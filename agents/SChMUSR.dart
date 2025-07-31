import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:async/async.dart';
import 'package:collection/collection.dart';
// ignore: unused_import
import 'package:dart_random_choice/dart_random_choice.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:riverpod/riverpod.dart';
import '../../../jhg_core.dart';
import '../common.dart';

final chatterBotAgentProvider = Provider.autoDispose(
  ChatterBotAgent.new,
  dependencies: [...agentProviders],
);

class ChatterBotAgent extends GeneAgent {
  ChatterBotAgent(
    super.ref, {
    super.genes,
    super.numGeneCopies,
    this.logfile,
    this.useFear = true,
  });

  final File? logfile;
  final bool useFear;

  Set<ChatMessageId> viewedMessages = {};
  Set<String>? nextGroup = {};
  Set<String>? lastGroup = {};
  Set<Set<String>> prevGroups = {};
  Map<String, int> tentativeTransactions = {};
  Map<String, int> announcedTransactions = {};
  List<String> announcedAttacks = [];
  List<String> announcedAlterations = [];
  List<String> announcedFear = [];
  List<String> announcedPotentialAttacks = [];
  List<String> proposedAttacks = [];
  Map<String, int> lastTransactions = {};
  Map<Set<String>, String> observationsAlreadyMade = {};
  Set<String> previousMostPowerful = {};
  Map<String, int> allocationsStatedByOthers = {};
  Map<String, int> prevAllocationsStatedByOthers = {};
  List<Set<String>> groupsProposedByOthers = [];

  CancelableOperation sendingChats = CancelableOperation.fromFuture(
    Future.value('initial value'),
  );
  int resendCounter = 0;

  Timer? submitTimer;
  Timer? roundEndTimer;
  bool changed = false;

  /// A matrix of players vs if they want to be in a group with another player.
  /// * chatGroupAgreement[A\][B\] is whether A wants B in their group
  /// * 1 is yes, 0 is unknown, and -1 is no
  ///
  /// This matrix currently decays at a hard coded rate
  Map<String, Map<String, double>> chatAgreement = {};

  /// A matrix of players to how much they plan to attack someone
  /// - attackClaims[A\][B\] is how much A plans to attack B
  Map<String, Map<String, double>> attackClaims = {};

  /// A matrix of players to whether they will attack someone
  /// - potentialAttackClaims[A\][B\] is how much A plans to attack B
  Map<String, Map<String, double>> potentialAttackClaims = {};

  //Trust map - based on how much they reciprocate, if they betray their friends, if they betray you, etc. and your trust gene
  Map<String, double> trustMap = {};
  Map<String, double> accusedOfAttacking = {};
  Map<String, double> accusedOfLying = {};

  Map<String, double> fear = {};
  Map<Set<String>, double> groupFear = {};

  /// * othersFear[A\][B\] = 1 means A fears B
  Map<String, Map<String, double>> othersFear = {};

  static const NUM_ALTERATIONS_FOR_NEW_GROUP = 3;
  static const GROWTH_WINDOW = 4;

  /// Rate at which chatAgreement decays each round
  static const DECAY_RATE = .9;

  // Simulation parameters (Will remove delays so the games can go faster)
  static const simulating = true;

  ///Number of milliseconds to wait after the last chat to submit
  static const SUBMIT_DELAY = simulating ? 250 : 20000;

  ///Toggles whether the randomWait function will actually wait
  static const WAIT = !simulating;

  ///true is the agent can expect everyone to respond to their messages
  static const EXPECT_RESPONSES = simulating;

  ///Toggles whether to use the list of dumb chat names or just list the players with a random number
  static const USE_REAL_CHAT_NAMES = !simulating;

  final dumbGroupProposals = [
    'Friends?',
    "Let's form a group",
    "Let's form a secret group",
  ];
  final listOfReasoning = [
    'It will make us more modular',
    'I like them',
    "I don't like them",
    'It will make us stronger',
    'We will be a better size',
    'We are more connected',
    'We are all giving to each other',
    'They are not giving enough',
    'They want to be in our group',
    "They don't want to be in our group",
    'I trust them',
    "I don't trust them",
  ];

  @override
  String get agentType => 'Chatter Bot $genes';

  List<String> msgs = [];

  @override
  Future<void> newMessage() async {
    await initializationCompleter.future;
    if (conversations != null) {
      for (final conversation in conversations!) {
        if (!conversation.participants.contains(myPlayerName)) {
          continue;
        }

        for (final messageEntry in conversation.messages.entries) {
          if (viewedMessages.contains(messageEntry.key)) {
            continue;
          }
          viewedMessages.add(messageEntry.key);
          final message = messageEntry.value;
          if (message is IdentifiedChatMessage) {
            //Ignore messages you send
            if (message.from == myPlayerName) {
              continue;
            }

            final sortedMessageStrings =
                conversation.messages.entries
                    .sortedBy((element) => element.value.time)
                    .map((e) => e.value.body)
                    .toList();
            final sortedMessages =
                conversation.messages.entries
                    .sortedBy((element) => element.value.time)
                    .map((e) => e.value)
                    .toList();

            //Someone calls you out by name
            if (message.body.toLowerCase().contains(
                  myPlayerName.toLowerCase(),
                ) ||
                conversation.participants.length <= 2) {
              // Sending you X
              if (message.body.toLowerCase().contains('sending')) {
                final amount = getAmounts(message).firstOrNull ?? 0;
                allocationsStatedByOthers[message.from] = amount;
              }

              //Asks you to join their group
              if (message.body.toLowerCase().contains(
                'would you like to join our group',
              )) {
                final playersToAdd = getMentionedPlayerNames(message);

                groupsProposedByOthers.add(conversation.participants);
                for (final player in conversation.participants) {
                  for (final playerToAdd in playersToAdd) {
                    chatAgreement[player]![playerToAdd] = 1;
                  }
                }

                await reevaluate();

                if (conversation.participants.every(nextGroup!.contains)) {
                  await sendMessage('Yes', conversation.conversationId);
                } else {
                  await sendMessage('No', conversation.conversationId);
                }

                await cancelAndResendChats();
              }

              //How much are you sending?
              if (message.body.toLowerCase().contains(
                'how much are you sending to',
              )) {
                final mentionedPlayers = getMentionedPlayerNames(message);
                for (final player in mentionedPlayers) {
                  var amountGiving = tentativeTransactions[player];
                  if ((amountGiving ?? 0) < 0) {
                    amountGiving = 0;
                  }
                  await sendMessage(
                    'Sending you $amountGiving',
                    conversation.conversationId,
                  );
                }
              } else if (message.body.toLowerCase().contains(
                'how much are you sending',
              )) {
                var amountGiving = tentativeTransactions[message.from];
                if ((amountGiving ?? 0) < 0) {
                  amountGiving = 0;
                }
                await sendMessage(
                  'Sending you $amountGiving',
                  conversation.conversationId,
                );
              }

              //How much are you stealing?
              if (message.body.toLowerCase().contains(
                'how much are you stealing',
              )) {
                if (nextGroup?.contains(message.from) ?? false) {
                  final stealing = tentativeTransactions.entries.where(
                    (element) => element.value < 0,
                  );

                  if (stealing.isEmpty) {
                    await sendMessage(
                      'I am not stealing',
                      conversation.conversationId,
                    );
                  }

                  for (final steal in stealing) {
                    await sendMessage(
                      'Stealing ${steal.value} from ${steal.key}',
                      conversation.conversationId,
                    );
                  }
                }
              }

              //How much are you keeping?
              if (message.body.toLowerCase().contains(
                'how much are you keeping',
              )) {
                if (nextGroup?.contains(message.from) ?? false) {
                  final amountKeeping = tentativeTransactions[myPlayerName];

                  await sendMessage(
                    'I am keeping $amountKeeping',
                    conversation.conversationId,
                  );
                }
              }

              //State observations
              if (message.body.toLowerCase().contains('observations')) {
                await stateObservations(
                  getCommunityEval(nextGroup)!,
                  conversation.conversationId,
                );
              }

              //
            }

            //Someone proposes a group
            if (dumbGroupProposals.contains(message.body)) {
              groupsProposedByOthers.add(conversation.participants);
              for (final player in conversation.participants) {
                if (player != message.from) {
                  chatAgreement[message.from]![player] = 1;
                }
              }

              await reevaluate();

              if (nextGroup?.containsAll(conversation.participants) ?? false) {
                await sendMessage('Yes', conversation.conversationId);
              } else {
                await sendMessage('No', conversation.conversationId);
              }
              await cancelAndResendChats();
            }

            //Someone suggests to drop a player
            if (message.body.toLowerCase().contains('drop')) {
              announcedAlterations.add(message.body.toLowerCase());

              final playersToDrop = getMentionedPlayerNames(message);
              groupsProposedByOthers.add(conversation.participants);

              for (final player in playersToDrop) {
                chatAgreement[message.from]![player] = -1;
              }

              await reevaluate();

              if (!playersToDrop.any(nextGroup?.contains ?? (e) => false)) {
                await sendMessage('Yes', conversation.conversationId);
              } else {
                await sendMessage('No', conversation.conversationId);
              }
              await cancelAndResendChats();
            }

            //Someone suggests to add a player
            if (message.body.toLowerCase().contains('add')) {
              announcedAlterations.add(message.body.toLowerCase());

              final playersToAdd = getMentionedPlayerNames(message);

              for (final player in playersToAdd) {
                chatAgreement[message.from]![player] = 1;
              }

              groupsProposedByOthers.add({
                ...conversation.participants,
                ...playersToAdd,
              });

              await reevaluate();

              if (nextGroup?.containsAll(playersToAdd) ?? false) {
                await sendMessage('Yes', conversation.conversationId);
              } else {
                await sendMessage('No', conversation.conversationId);
              }
              await cancelAndResendChats();
            }

            //Someone suggests to replace a player
            if (message.body.toLowerCase().contains('replace')) {
              announcedAlterations.add(message.body.toLowerCase());
              final playersToAdd = <String>[];
              final playersToDrop = <String>[];
              final tokenizedMessage = message.body.toLowerCase().split(' ');
              final idxWith = tokenizedMessage.indexOf('with');
              final firstChunk = tokenizedMessage.sublist(0, idxWith);
              final secondChunk = tokenizedMessage.sublist(idxWith);

              for (final player in currentRound.info.groupMembers) {
                if (firstChunk.contains(player.toLowerCase())) {
                  chatAgreement[message.from]![player] = -1;
                  playersToDrop.add(player);
                }
                if (secondChunk.contains(player.toLowerCase())) {
                  chatAgreement[message.from]![player] = 1;
                  playersToAdd.add(player);
                }
              }

              groupsProposedByOthers.add({
                ...conversation.participants,
                ...playersToAdd,
              });

              await reevaluate();

              if ((nextGroup?.containsAll(playersToAdd) ?? false) &&
                  (!playersToDrop.any(nextGroup?.contains ?? (e) => false))) {
                await sendMessage('Yes', conversation.conversationId);
              } else {
                await sendMessage('No', conversation.conversationId);
              }

              await cancelAndResendChats();
            }

            //Someone accuses someone else of not giving
            if (message.body.toLowerCase().contains('did not give')) {
              final playersAccused = getMentionedPlayerNames(message);
              for (final player in playersAccused) {
                //Update trust based on how much you trust the accusor
                trustMap[player] =
                    trustMap[player]! -
                    activeGenes!.distrustRate / 100 * trustMap[message.from]!;
                if (trustMap[player]! < 0) {
                  trustMap[player] = 0;
                }

                // Update accusations based on how much you trust the accusor
                accusedOfLying[player] =
                    accusedOfLying[player]! + trustMap[message.from]!;

                changed = true;
              }

              await reevaluate();
              await cancelAndResendChats();
            }

            // Someone accuses someone else of stealing
            if (message.body.toLowerCase().contains('attacked')) {
              final playersAccused = getMentionedPlayerNames(message);
              for (final player in playersAccused) {
                //Update trust based on how much you trust the accusor
                trustMap[player] =
                    trustMap[player]! -
                    activeGenes!.distrustRate / 100 * trustMap[message.from]!;
                if (trustMap[player]! < 0) {
                  trustMap[player] = 0;
                }

                // Update accusations based on how much you trust the accusor
                accusedOfAttacking[player] =
                    accusedOfAttacking[player]! + trustMap[message.from]!;

                changed = true;
              }

              await reevaluate();
              await cancelAndResendChats();
            }

            //TODO: Someone accuses someone else of not attacking

            // I am attacking
            if (message.body.toLowerCase().contains('am attacking')) {
              final playersToAttack = getMentionedPlayerNames(message);
              final amounts = getAmounts(message);

              if (amounts.length < playersToAttack.length) {
                print('Amounts and players to attack do not match');
                // Ask for amount if they did not say

                await sendMessage(
                  'How much are you stealing?',
                  conversation.conversationId,
                );
              } else {
                for (var i = 0; i < playersToAttack.length; i++) {
                  attackClaims[message.from]![playersToAttack[i]] =
                      amounts[i].toDouble();
                }

                changed = true;
                await reevaluate();
                await cancelAndResendChats();
              }

              //Potential attacks
            } else if (message.body.toLowerCase().contains('attack')) {
              // I will attack
              if (message.body.toLowerCase().contains('will attack')) {
                final playersToAttack = getMentionedPlayerNames(message);

                for (var i = 0; i < playersToAttack.length; i++) {
                  potentialAttackClaims[message.from]![playersToAttack[i]] = 1;
                }

                changed = true;
                await reevaluate();
                await cancelAndResendChats();
              } else {
                final playersToAttack = getMentionedPlayerNames(message);
                for (final player in playersToAttack) {
                  if (potentialAttackClaims[message.from]![player] != 1) {
                    changed = true;
                  }
                  potentialAttackClaims[message.from]![player] = 1;
                }

                proposedAttacks.add(message.body);

                if (changed) {
                  await reevaluate();
                  await cancelAndResendChats();
                }
              }
            }

            // If message contains an int (and is a response to inquires about attacking)
            // It's a little janky when getting amounts and (especially as responses), maybe a language model could help?
            if (message.body.contains(RegExp(r'\d'))) {
              var previousMessageIdx = sortedMessageStrings.length - 2;
              if (previousMessageIdx >= 0 &&
                  sortedMessageStrings[previousMessageIdx] ==
                      'With how many?') {
                previousMessageIdx--;

                while (previousMessageIdx >= 0 &&
                    (sortedMessages[previousMessageIdx]
                            is IdentifiedChatMessage &&
                        message.from !=
                            (sortedMessages[previousMessageIdx]
                                    as IdentifiedChatMessage)
                                .from)) {
                  previousMessageIdx--;
                }

                if (previousMessageIdx >= 0) {
                  if (sortedMessageStrings[previousMessageIdx]
                      .toLowerCase()
                      .contains('attacking')) {
                    final amounts = getAmounts(message);
                    final playersToAttack = getMentionedPlayerNames(
                      sortedMessages[previousMessageIdx]
                          as IdentifiedChatMessage,
                    );

                    if (amounts.length == playersToAttack.length) {
                      for (var i = 0; i < playersToAttack.length; i++) {
                        attackClaims[message.from]![playersToAttack[i]] =
                            amounts[i].toDouble();
                      }

                      changed = true;
                      await reevaluate();
                      await cancelAndResendChats();
                    } else {
                      print('message: ${message.body}');
                      print('amounts: $amounts players: $playersToAttack');
                      print('Not sure who and how much they are attacking');
                    }
                  }
                }
              }
            }

            //Same as last round
            if (message.body.toLowerCase() == 'same as last round') {
              allocationsStatedByOthers[message.from] =
                  prevAllocationsStatedByOthers[message.from] ?? 0;
            }

            //Sending you each
            if (message.body.toLowerCase().contains('each')) {
              final lastWord = message.body.split(' ');
              allocationsStatedByOthers[message.from] =
                  int.tryParse(lastWord[lastWord.length - 1]) ?? 0;
            }

            //Comparing to group
            if (message.body.toLowerCase().contains('more powerful')) {
              final morePowerfulGroup = getMentionedPlayerNames(message);

              if (morePowerfulGroup.isEmpty) {
                var previousMessageIdx = sortedMessages.length - 1;
                while (previousMessageIdx >= 0 &&
                    (sortedMessages[previousMessageIdx]
                        is IdentifiedChatMessage) &&
                    (((sortedMessages[previousMessageIdx]
                                    as IdentifiedChatMessage)
                                .from !=
                            message.from) ||
                        sortedMessages[previousMessageIdx].body ==
                            message.body)) {
                  previousMessageIdx--;
                }

                if (previousMessageIdx >= 0) {
                  morePowerfulGroup.addAll(
                    getMentionedPlayerNames(
                      sortedMessages[previousMessageIdx]
                          as IdentifiedChatMessage,
                    ),
                  );
                }
              }

              observationsAlreadyMade.removeWhere(
                (key, value) => key.deepEquals(morePowerfulGroup),
              );
              observationsAlreadyMade[morePowerfulGroup.toSet()] = message.body;
            }

            //Most powerful group
            if (message.body.toLowerCase().contains('most powerful')) {
              if (nextGroup?.deepEquals(conversation.participants) ?? false) {
                if (message.body.toLowerCase().contains('we are')) {
                  previousMostPowerful = conversation.participants;
                } else {
                  final mostPowerfulGroup = getMentionedPlayerNames(message);

                  previousMostPowerful = mostPowerfulGroup.toSet();
                }
              }
            }

            //Players not in a group
            if (message.body.toLowerCase().contains('not in a group')) {
              final playerNotInGroup =
                  getMentionedPlayerNames(message).firstOrNull;

              if (playerNotInGroup != null) {
                observationsAlreadyMade.removeWhere(
                  (key, value) => key.deepEquals({playerNotInGroup}),
                );
                observationsAlreadyMade[{playerNotInGroup}] = message.body;
              }
            }

            //Fear
            if (message.body.toLowerCase().contains('afraid of')) {
              final playersFeared = getMentionedPlayerNames(message);
              for (final player in playersFeared) {
                if (othersFear[message.from]![player] != 1) {
                  changed = true;
                }
                othersFear[message.from]![player] = 1;
              }

              if (changed) {
                await reevaluate();
                await cancelAndResendChats();
              }
            }

            //A player agreed to something
            if (message.body.toLowerCase() == 'yes') {
              await playerAgreed(sortedMessageStrings, conversation, message);
            }

            // A player disagreed with something
            if (message.body.toLowerCase() == 'no') {
              await playerDisagreed(
                sortedMessageStrings,
                conversation,
                message,
              );
            }
          }
        }
      }
    }
  }

  Future<void> playerDisagreed(
    List<String> sortedMessageStrings,
    Conversation conversation,
    IdentifiedChatMessage message,
  ) async {
    var previousMessageIdx = sortedMessageStrings.length - 1;
    while (previousMessageIdx >= 0 &&
        (sortedMessageStrings[previousMessageIdx].toLowerCase() == 'yes' ||
            sortedMessageStrings[previousMessageIdx].toLowerCase() == 'no')) {
      previousMessageIdx--;
    }

    //This helps with the case where two or more bots send a message at the same time and everyone responds to each
    if (EXPECT_RESPONSES) {
      var numberOfOtherResponses =
          sortedMessageStrings.length - 1 - previousMessageIdx;

      final indexesOfQuestions = [
        (
          previousMessageIdx,
          numExpectedResponses(
            sortedMessageStrings[previousMessageIdx],
            conversation.participants.length,
          ),
        ),
      ];

      previousMessageIdx--;
      while (previousMessageIdx > 0 &&
          isQuestion(sortedMessageStrings[previousMessageIdx])) {
        indexesOfQuestions.add((
          previousMessageIdx,
          numExpectedResponses(
            sortedMessageStrings[previousMessageIdx],
            conversation.participants.length,
          ),
        ));
        previousMessageIdx--;
      }

      for (final question in indexesOfQuestions.reversed) {
        previousMessageIdx = question.$1;
        final expectedResponses = question.$2;
        numberOfOtherResponses -= expectedResponses;
        if (numberOfOtherResponses < 0) {
          break;
        }
      }
    }

    //If the last message was a group proposal and this is a response
    if (dumbGroupProposals.contains(sortedMessageStrings[previousMessageIdx])) {
      for (final player in conversation.participants) {
        if (player != message.from) {
          // chatAgreement[message.from]![player] = -1; // Not necessarily true that they don't want everyone in the group
        }
      }
    }
    //If last message was reaching out to someone
    if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
          'would you like to join our group',
        ) &&
        sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
          message.from.toLowerCase(),
        )) {
      for (final player in conversation.participants) {
        if (player != message.from) {
          // chatAgreement[message.from]![player] = -1; // Not necessarily true that they don't want everyone in the group
        }
      }
    }

    //If last message was a proposal to drop a player
    if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
      'drop',
    )) {
      for (final player in currentRound.info.groupMembers) {
        if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
          player.toLowerCase(),
        )) {
          chatAgreement[message.from]![player] = 1;
        }
      }
    }

    //If last message was a proposal to add a player
    if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
      'add',
    )) {
      for (final player in currentRound.info.groupMembers) {
        if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
          player.toLowerCase(),
        )) {
          chatAgreement[message.from]![player] = -1;
        }
      }
    }

    await reevaluate();
    await cancelAndResendChats();
  }

  bool isQuestion(String message) {
    //If the last message was a group proposal and this is a response
    if (dumbGroupProposals.contains(message)) {
      return true;
    }

    //If last message was reaching out to someone
    if (message.toLowerCase().contains('would you like to join our group')) {
      return true;
    }

    //If last message was a proposal to drop a player
    if (message.toLowerCase().contains('drop')) {
      return true;
    }

    //If last message was a proposal to add a player
    if (message.toLowerCase().contains('add')) {
      return true;
    }

    return false;
  }

  int numExpectedResponses(String message, int numParticipants) {
    //If last message was reaching out to someone
    if (message.toLowerCase().contains('would you like to join our group')) {
      final mentionedNames = getMentionedPlayerNames(
        IdentifiedChatMessage(from: '', body: message, time: DateTime.now()),
      );
      return mentionedNames.length;
    }

    return numParticipants - 1;
  }

  Future<void> playerAgreed(
    List<String> sortedMessageStrings,
    Conversation conversation,
    IdentifiedChatMessage message,
  ) async {
    var previousMessageIdx = sortedMessageStrings.length - 1;
    while (previousMessageIdx >= 0 &&
        (sortedMessageStrings[previousMessageIdx].toLowerCase() == 'yes' ||
            sortedMessageStrings[previousMessageIdx].toLowerCase() == 'no')) {
      previousMessageIdx--;
    }

    //This helps with the case where two or more bots send a message at the same time and everyone responds to each
    if (EXPECT_RESPONSES) {
      var numberOfOtherResponses =
          sortedMessageStrings.length - 1 - previousMessageIdx;

      final indexesOfQuestions = [
        (
          previousMessageIdx,
          numExpectedResponses(
            sortedMessageStrings[previousMessageIdx],
            conversation.participants.length,
          ),
        ),
      ];

      previousMessageIdx--;
      while (previousMessageIdx > 0 &&
          isQuestion(sortedMessageStrings[previousMessageIdx])) {
        indexesOfQuestions.add((
          previousMessageIdx,
          numExpectedResponses(
            sortedMessageStrings[previousMessageIdx],
            conversation.participants.length,
          ),
        ));
        previousMessageIdx--;
      }

      for (final question in indexesOfQuestions.reversed) {
        previousMessageIdx = question.$1;
        final expectedResponses = question.$2;
        numberOfOtherResponses -= expectedResponses;
        if (numberOfOtherResponses < 0) {
          break;
        }
      }
    }

    //If the last message was a group proposal and this is a response
    if (dumbGroupProposals.contains(sortedMessageStrings[previousMessageIdx])) {
      for (final player in conversation.participants) {
        if (player != message.from) {
          chatAgreement[message.from]![player] = 1;
        }
      }
    }

    //If last message was reaching out to someone
    if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
          'would you like to join our group',
        ) &&
        sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
          message.from.toLowerCase(),
        )) {
      for (final player in conversation.participants) {
        chatAgreement[message.from]![player] = 1;
      }
    }

    //If last message was a proposal to drop a player
    if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
      'drop',
    )) {
      for (final player in currentRound.info.groupMembers) {
        if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
          player.toLowerCase(),
        )) {
          chatAgreement[message.from]![player] = -1;
        }
      }
    }

    //If last message was a proposal to add a player
    if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
      'add',
    )) {
      for (final player in currentRound.info.groupMembers) {
        if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
          player.toLowerCase(),
        )) {
          chatAgreement[message.from]![player] = 1;
        }
      }
    }

    //If last message was a proposal to replace a player
    if (sortedMessageStrings[previousMessageIdx].toLowerCase().contains(
      'replace',
    )) {
      final playersToAdd = <String>[];
      final playersToDrop = <String>[];
      final tokenizedMessage = sortedMessageStrings[previousMessageIdx]
          .toLowerCase()
          .toLowerCase()
          .split(' ');
      final idxWith = tokenizedMessage.indexOf('with');
      final firstChunk = tokenizedMessage.sublist(0, idxWith);
      final secondChunk = tokenizedMessage.sublist(idxWith);

      for (final player in currentRound.info.groupMembers) {
        if (firstChunk.contains(player.toLowerCase())) {
          playersToDrop.add(player);
        }
        if (secondChunk.contains(player.toLowerCase())) {
          playersToAdd.add(player);
        }
      }

      for (final player in playersToAdd) {
        chatAgreement[message.from]![player] = 1;
      }
    }

    await reevaluate();
    await cancelAndResendChats();
  }

  ///Pulls all the player names out of a chat message in order of occurrence
  List<String> getMentionedPlayerNames(IdentifiedChatMessage message) {
    final players =
        currentRound.info.groupMembers; //.map((e) => e.toLowerCase());
    // if (players.any((element) => element.toLowerCase().contains(' '))) {
    //   // ignore: avoid_print
    //   print('The agent cannot handle spaces in player names. Please reconsider the nameset');
    // }

    final mentionedPlayers = <String>[];

    // //Removes all characters that aren't letters or spaces
    // final cleanedMessage = message.body.replaceAll(RegExp(r'[^\w\s-]'), '');
    // final splitMessage = cleanedMessage.split(' ');
    // for (final word in splitMessage) {
    //   if (players.contains(word.toLowerCase())) {
    //     mentionedPlayers.add(word.capitalize());
    //   }
    // }

    final lowercaseMessage = message.body.toLowerCase();

    for (final player in players) {
      if (lowercaseMessage.contains(player.toLowerCase())) {
        mentionedPlayers.add(player);
      }
    }

    return mentionedPlayers;
  }

  ///Pulls all integers out of a chat message in order of occurrence
  List<int> getAmounts(IdentifiedChatMessage message) {
    final amounts = <int>[];
    final splitMessage = message.body.split(' ');
    for (final word in splitMessage) {
      final amount = int.tryParse(word);
      if (amount != null) {
        amounts.add(amount);
      }
    }

    return amounts;
  }

  ///Finds the ID of the first conversation containing the list of players, if none exists, it creates one
  Future<String?> getConversationWith(List<String> players) async {
    if (conversations != null) {
      final conversation = conversations!.firstWhereOrNull((element) {
        return element.participants.deepEquals({
          myPlayerName,
          ...players,
        }, ignoreOrder: true);
      });

      if (conversation == null) {
        return (await createConversationWith(players))?.conversationId;
      }

      return conversation.conversationId;
    } else {
      return (await createConversationWith(players))?.conversationId;
    }
  }

  final dumbChatNames = [
    'Friends',
    'Squad',
    'Winners',
    'Alliance',
    'asdf',
    'Homies',
    'Group up?',
    'We are family',
    'Team Awesome',
    'Yum yum',
    'Group',
    'trade',
    'BFFs',
    'Best buddies',
    'Buddies',
    'Howdy',
    'yoooo',
    'The Real Friends',
    'Team?',
    'The Fam',
    'The team',
    'Conversation',
    'Unite',
    'We can be friends',
    'Partners in Crime',
    'Victory Vibes',
    'Circle of Trust',
    'Forever Friends',
    'United Minds',
    'No Cap Crew',
    'Gucci Gang',
    '#SquadGoals',
    'Savage',
    'The Crew',
    'Woke',
    'Chat Cha-Ching',
    'Yasss',
    'The Real MVPs',
    'Hangry Homies',
    "Sippin' on the Tea",
    'yolo',
    'Glow up',
    'tmi',
    'Slay',
    'Hype',
    'qwerty',
    '#NoFilter',
    'Cringe',
    'We are the most powerful group',
  ];

  ///Creates a conversation with the list of players, a name may be provided, otherwise a
  ///default name will be made
  Future<Conversation?> createConversationWith(
    List<String> players, {
    String? name,
  }) async {
    final allConversationNames = conversations?.map((e) => e.name) ?? [];
    dumbChatNames.removeWhere(allConversationNames.contains);

    final participants = {myPlayerName, ...players};
    String randomName;

    if (dumbChatNames.isEmpty || !USE_REAL_CHAT_NAMES) {
      //If all the names are taken, the name will be the players in the chat plus a random number
      randomName =
          '${getStringOfPlayers(participants.toList())} ${Random().nextDouble()}';
    } else {
      randomName = randomChoice(dumbChatNames);
    }

    final success = await createConversation(
      name ?? randomName,
      participants.toList(),
    );
    if (!success && dumbChatNames.isNotEmpty && USE_REAL_CHAT_NAMES) {
      dumbChatNames.remove(randomName);
      return createConversationWith(players, name: name);
    }

    Conversation? conversation;

    conversation = conversations!.firstWhereOrNull((element) {
      return element.participants.deepEquals({
        myPlayerName,
        ...players,
      }, ignoreOrder: true);
    });

    //Might need to wait a bit for the conversation to be created, so keep trying to find it every
    //200ms until it's tried 5 times, then give up
    for (var i = 0; i < 5; i++) {
      if (conversation == null) {
        await Future<void>.delayed(const Duration(milliseconds: 500));

        conversation = conversations!.firstWhereOrNull((element) {
          return element.participants.deepEquals({
            myPlayerName,
            ...players,
          }, ignoreOrder: true);
        });
      }
    }

    if (conversation == null) {
      print('Could not find conversation with $players');
    }

    return conversation;
  }

  Future<String?> maybeGetConversationWith(
    List<String> players,
    int resendCount,
  ) async {
    if (resendCount != resendCounter) return null;

    return getConversationWith(players);
  }

  Future<bool> maybeSendMessage(
    String message,
    String conversationId,
    int resendCount,
  ) async {
    if (reevaluateCounter > 100) {
      logfile?.writeAsStringSync('$message\n', mode: FileMode.append);
    }

    if (resendCount != resendCounter) return false;

    return sendMessage(message, conversationId);
  }

  // Logs messages for debugging
  @override
  Future<bool> sendMessage(String message, String conversationId) async {
    logfile?.writeAsStringSync(
      '${DateTime.now()} $myPlayerName: $message\n',
      mode: FileMode.append,
    );

    return super.sendMessage(message, conversationId);
  }

  var initializationCompleter = Completer<void>();
  int reevaluateCounter = 0;

  @override
  Future<void> nextRound() async {
    reevaluateCounter = 0;
    logfile?.writeAsStringSync(
      'ChatterBot $myPlayerName round ${currentRound.info.round}\n',
      mode: FileMode.append,
    );
    //Submit 15 seconds prior to the end of the round
    roundEndTimer?.cancel();
    roundEndTimer = Timer(
      currentRound.info.endTime.difference(DateTime.now()) -
          const Duration(seconds: 15),
      () async {
        submitTimer?.cancel();
        await submitTentativeTransactions();
      },
    );

    final roundNum = currentRound.info.round;
    final numPlayers = currentRound.info.groupMembers.length;
    final numTokens = currentRound.info.playerTokens;
    visualTraits = {
      for (final player in currentRound.info.playerPopularities.keys) player: 0,
    };

    if (activeGenes == null) initializeGenes();

    if (roundNum == initialRound) {
      initVars();
      initChatVars();
      initializationCompleter.complete();
    } else {
      updateVars();
      updateChatVars();
    }

    alpha = activeGenes!.alpha / 100;

    computeUsefulQuantities();
    calculateIndividualFear();

    if (roundNum == initialRound) {
      await randomWait(10);
    }

    await randomWait(10); //TODO: consider only doing this on the first round

    // group analysis and choice
    final groupAnalysisRes = groupAnalysis();
    final communities = groupAnalysisRes.first;
    final selectedCommunity = groupAnalysisRes.second;

    communities.forEach(calculateGroupFear);

    // figure out how many tokens to keep
    estimateKeeping(numPlayers, communities);

    final bool safetyFirst;
    if (activeGenes!.safetyFirst < 50) {
      safetyFirst = false;
    } else {
      safetyFirst = true;
    }

    var guardoToks = cuantoGuardo(selectedCommunity.s);

    // determine who to attack (if any)
    final Map<String, int> attackAlloc;
    final int numAttackToks;
    var remainingToks = 0;
    if (roundNum > initialRound) {
      remainingToks = currentRound.info.playerTokens;
      if (safetyFirst) {
        remainingToks -= guardoToks;
      }

      envisionFearAttack(remainingToks, selectedCommunity.s);
      final atacoResult = quienAtaco(
        remainingToks,
        selectedCommunity.s,
        communities,
      );

      attackAlloc = atacoResult.first;
      numAttackToks = atacoResult.second;
    } else {
      attackAlloc = {
        for (final player in currentRound.info.playerPopularities.keys)
          player: 0,
      };
      remainingToks = numTokens - guardoToks;
      numAttackToks = 0;
    }

    // figure out who to give tokens to
    final groupsAlloc =
        groupGivings(
          numTokens - numAttackToks - guardoToks,
          selectedCommunity,
          attackAlloc,
        ).first;

    // update some variables
    final transactionVec = subtractIntVectors(groupsAlloc, attackAlloc);

    guardoToks =
        numTokens -
        transactionVec
            .map((key, value) => MapEntry(key, value.abs()))
            .values
            .sum;

    transactionVec[myPlayerName] = transactionVec[myPlayerName]! + guardoToks;

    prevPopularities = currentRound.info.playerPopularities;
    prevAllocations = transactionVec.map(
      (key, value) => MapEntry(key, value.toDouble()),
    );
    prevInfluence = transposeMap(
      removeIntrinsic(currentRound.info.playerInfluences),
    );

    updateIndebtedness(transactionVec);
    // print('updated indebtedness');

    if (transactionVec[myPlayerName]! < 0) {
      // ignore: avoid_print
      print('$myPlayerName is stealing from self!!!');
    }

    nextGroup = selectedCommunity.s;
    tentativeTransactions = Map.from(transactionVec);

    submitTimer?.cancel();
    submitTimer = Timer(const Duration(milliseconds: SUBMIT_DELAY), () async {
      await submitTentativeTransactions();
    });

    // print(
    //     'ChatterBot $myPlayerName transactions: ${transactionVec.map((key, value) => MapEntry(key, value.toDouble()))}');

    //Send chats
    if (gameParams.chatType == ChatType.direct) {
      sendingChats = CancelableOperation.fromFuture(resendChats());
      await sendingChats.value;
      await sendInitialChats(selectedCommunity, transactionVec, attackAlloc);
    } else {
      submitTimer?.cancel();
      await submitTentativeTransactions();
    }
  }

  Future<void> submitTentativeTransactions() async {
    await Future<void>.delayed(Duration(milliseconds: Random().nextInt(1000)));
    // print('chatterbot $myPlayerName submitting transactions');
    logfile?.writeAsStringSync(
      'chatterbot $myPlayerName submitting transactions\n',
      mode: FileMode.append,
    );
    await submitTransactions(
      tentativeTransactions.map(
        (key, value) => MapEntry(key, value.toDouble()),
      ),
    );
  }

  void initChatVars() {
    trustMap = {
      for (final player in currentRound.info.groupMembers)
        player: activeGenes!.startingTrust / 100,
    };
    chatAgreement = {
      for (final player in currentRound.info.groupMembers)
        player: {
          for (final player in currentRound.info.groupMembers) player: 0,
        },
    };
    attackClaims = {
      for (final player in currentRound.info.groupMembers)
        player: {
          for (final player in currentRound.info.groupMembers) player: 0,
        },
    };
    potentialAttackClaims = {
      for (final player in currentRound.info.groupMembers)
        player: {
          for (final player in currentRound.info.groupMembers) player: 0,
        },
    };
    othersFear = {
      for (final player in currentRound.info.groupMembers)
        player: {
          for (final player in currentRound.info.groupMembers) player: 0,
        },
    };
    fear = {for (final player in currentRound.info.groupMembers) player: 0};
    clearAccusations();
  }

  // TODO: Should accusations be cleared each round, persist, or decay?
  void clearAccusations() {
    accusedOfAttacking = {
      for (final player in currentRound.info.groupMembers) player: 0,
    };
    accusedOfLying = {
      for (final player in currentRound.info.groupMembers) player: 0,
    };

    // accusedOfAttacking = accusedOfAttacking.map((key, value) => MapEntry(key, value * DECAY_RATE));
    // accusedOfLying = accusedOfLying.map((key, value) => MapEntry(key, value * DECAY_RATE));
  }

  void updateChatVars() {
    prevAllocationsStatedByOthers = Map.from(allocationsStatedByOthers);
    allocationsStatedByOthers = {};
    // groupsProposedByOthers = [];
    announcedTransactions = {};
    announcedAttacks = [];
    announcedAlterations = [];
    announcedFear = [];
    announcedPotentialAttacks = [];
    proposedAttacks = [];
    lastTransactions = Map.from(tentativeTransactions);
    clearAccusations();

    updateTrustMap();
    updateChatAgreements();

    attackClaims = {
      for (final player in currentRound.info.groupMembers)
        player: {
          for (final player in currentRound.info.groupMembers) player: 0,
        },
    };

    potentialAttackClaims = {
      for (final player in currentRound.info.groupMembers)
        player: {
          for (final player in currentRound.info.groupMembers) player: 0,
        },
    };

    othersFear.forEach((key, value) => value.updateAll((key, value) => 0));
    groupFear = {};
  }

  void updateTrustMap() {
    for (final player in currentRound.info.groupMembers) {
      final amountTheyStated = prevAllocationsStatedByOthers[player] ?? 0;
      final amountTheyGave = currentRound.info.tokensReceived?[player] ?? 0;

      //TODO: fix the calculations for this?

      if (amountTheyGave < amountTheyStated) {
        // final difference = amountTheyStated - amountTheyGave;

        trustMap[player] =
            trustMap[player]! -
            activeGenes!.distrustRate /
                100; // * (difference / currentRound.info.playerTokens +1); //Does this need to be scaled by severity?
        if (trustMap[player]! < 0) {
          trustMap[player] = 0;
        }
      }

      // TODO: they said they would attack and did not. Can this be detected?

      if (amountTheyStated > 0 && amountTheyGave >= amountTheyStated) {
        trustMap[player] = trustMap[player]! + activeGenes!.trustRate / 100;
        if (trustMap[player]! > 1) {
          trustMap[player] = 1;
        }
      }
    }
  }

  void updateChatAgreements() {
    chatAgreement = chatAgreement.map(
      (key1, value1) => MapEntry(
        key1,
        value1.map((key2, value2) => MapEntry(key2, value2 * DECAY_RATE)),
      ),
    );
  }

  Future<void> cancelAndResendChats() async {
    if (changed) {
      await sendingChats.cancel();
      sendingChats = CancelableOperation.fromFuture(resendChats());
      await sendingChats.value;
    }
    changed = false;
  }

  Future<void> sendInitialChats(
    CommunityEvaluation selectedCommunity,
    Map<String, int> transactionVec,
    Map<String, int> attackAlloc,
  ) async {
    await tellGroupWhoAttackedYou(transactionVec, selectedCommunity.s);
    await randomWait(10, minSeconds: 3);
    await tellGroupWhoLied(selectedCommunity.s);
    await randomWait(10);
  }

  Future<void> resendChats() async {
    resendCounter++;
    final resendCount = resendCounter;
    if ((nextGroup?.length ?? 0) < 2) {
      //  print('$myPlayerName is in a group of less than 2 $nextGroup');
    } else {
      if (resendCount != resendCounter) return;
      await proposeGroup(nextGroup!, resendCount);
      await alterGroup(
        getCommunityEval(nextGroup)!,
        resendCount,
        stateReason: false,
      );
    }

    await randomWait(10, minSeconds: 3);
    if (resendCount != resendCounter) return;
    await anounceFear(nextGroup!, resendCount);
    await randomWait(10, minSeconds: 3);
    if (resendCount != resendCounter) return;
    await announcePotentialAttacks(nextGroup!, resendCount);
    await randomWait(10, minSeconds: 3);
    if (resendCount != resendCounter) return;
    await announceAttacks(nextGroup!, tentativeTransactions, resendCount);
    await randomWait(20, minSeconds: 5);
    if (resendCount != resendCounter) return;
    await announceAllocations(tentativeTransactions, nextGroup!, resendCount);

    // Changed this to only state observations if asked
    // await randomWait(10);
    // await stateObservations(getCommunityEval(nextGroup)!);

    lastGroup = nextGroup;
    prevGroups.add(nextGroup!);
  }

  Future<void> reevaluate() async {
    //if (reevaluateCounter > 200) {
    //   logfile?.writeAsStringSync('ChatterBot $myPlayerName reevaluation limit reached\n',
    //       mode: FileMode.append);
    //   return;
    //  }
    final numTokens = currentRound.info.playerTokens;
    final numPlayers = currentRound.info.groupMembers.length;
    final roundNum = currentRound.info.round;

    calculateIndividualFear();

    // group analysis and choice
    final groupAnalysisRes = groupAnalysis();
    final communities = groupAnalysisRes.first;
    final selectedCommunity = groupAnalysisRes.second;

    if (roundNum == initialRound) {
      await randomWait(10);
    }

    //Everything changes if you change groups
    if (!selectedCommunity.s.deepEquals(nextGroup)) {
      changed = true;
    }

    //Only calculate everything if information has changed
    if (!changed) {
      return;
    }

    communities.forEach(calculateGroupFear);

    // figure out how many tokens to keep
    estimateKeeping(numPlayers, communities);

    final bool safetyFirst;
    if (activeGenes!.safetyFirst < 50) {
      safetyFirst = false;
    } else {
      safetyFirst = true;
    }

    var guardoToks = cuantoGuardo(selectedCommunity.s);

    // determine who to attack (if any)
    final Map<String, int> attackAlloc;
    final int numAttackToks;
    var remainingToks = 0;
    if (roundNum > initialRound) {
      remainingToks = currentRound.info.playerTokens;
      if (safetyFirst) {
        remainingToks -= guardoToks;
      }

      envisionFearAttack(remainingToks, selectedCommunity.s);
      final atacoResult = quienAtaco(
        remainingToks,
        selectedCommunity.s,
        communities,
      );

      attackAlloc = atacoResult.first;
      numAttackToks = atacoResult.second;
    } else {
      attackAlloc = {
        for (final player in currentRound.info.playerPopularities.keys)
          player: 0,
      };
      remainingToks = numTokens - guardoToks;
      numAttackToks = 0;
    }

    // figure out who to give tokens to
    final groupsAlloc =
        groupGivings(
          numTokens - numAttackToks - guardoToks,
          selectedCommunity,
          attackAlloc,
        ).first;

    // update some variables
    final transactionVec = subtractIntVectors(groupsAlloc, attackAlloc);

    guardoToks =
        numTokens -
        transactionVec
            .map((key, value) => MapEntry(key, value.abs()))
            .values
            .sum;

    transactionVec[myPlayerName] = transactionVec[myPlayerName]! + guardoToks;

    prevPopularities = currentRound.info.playerPopularities;
    prevAllocations = transactionVec.map(
      (key, value) => MapEntry(key, value.toDouble()),
    );
    prevInfluence = transposeMap(
      removeIntrinsic(currentRound.info.playerInfluences),
    );

    // updateIndebtedness(transactionVec);

    if (transactionVec[myPlayerName]! < 0) {
      // ignore: avoid_print
      print('$myPlayerName is stealing from self!!!');
    }

    nextGroup = selectedCommunity.s;
    tentativeTransactions = Map.from(transactionVec);

    // print(
    //     'ChatterBot $myPlayerName transactions: ${transactionVec.map((key, value) => MapEntry(key, value.toDouble()))}');

    if (roundEndTimer?.isActive ?? true) {
      reevaluateCounter++;

      logfile?.writeAsStringSync(
        'ChatterBot $myPlayerName reevaluating\n',
        mode: FileMode.append,
      );
      submitTimer?.cancel();
      submitTimer = Timer(const Duration(milliseconds: SUBMIT_DELAY), () async {
        await submitTentativeTransactions();
      });
    }
  }

  ///Wait a random number of seconds between 0 and [maxSeconds].
  ///[minSeconds] may be provided to wait between [minSeconds] and [maxSeconds]
  Future<void> randomWait(int maxSeconds, {int minSeconds = 0}) async {
    final randomNum = Random().nextInt(maxSeconds - minSeconds) + minSeconds;
    if (WAIT) {
      await Future<void>.delayed(Duration(seconds: randomNum));
    } else {
      // logfile?.writeAsStringSync('ChatterBot $myPlayerName waiting $randomNum milliseconds\n',
      //     mode: FileMode.append);
      await Future<void>.delayed(Duration(microseconds: randomNum * 10));
    }
  }

  String getStringOfPlayers(List<String> players) {
    if (players.length == 1) {
      return players[0];
    }

    var str = '';

    for (final player in players) {
      if (player == players.last) {
        str += ' and $player';
      } else if (player == players.first) {
        str += player;
      } else {
        str += ', $player';
      }
    }

    return str;
  }

  List<String> getAttackers() {
    final attackers = <String>[];

    for (final playerAllocation
        in (currentRound.info.tokensReceived ?? <String, double>{}).entries) {
      if (playerAllocation.value < 0) {
        attackers.add(playerAllocation.key);
      }
    }

    return attackers;
  }

  Completer<void>? proposeGroupCompleter;

  Future<void> proposeGroup(Set<String> group, int resendCount) async {
    if (proposeGroupCompleter != null) {
      await proposeGroupCompleter!.future;
    }

    proposeGroupCompleter = Completer<void>();

    var groupAlreadyMade = false;
    for (final groupFromPast in prevGroups) {
      if (groupFromPast.deepEquals(group, ignoreOrder: true)) {
        groupAlreadyMade = true;
      }

      var playersNotInPrev = 0;
      for (final player in group) {
        if (!groupFromPast.contains(player)) {
          playersNotInPrev++;
        }
      }

      var playersNotInGroup = 0;
      for (final player in groupFromPast) {
        if (!group.contains(player)) {
          playersNotInGroup++;
        }
      }

      //if the group differs by NUM_ALTERATIONS_FOR_NEW_GROUP or more players, it is a new group,
      //otherwise it is an altered group
      if (playersNotInGroup + playersNotInPrev <
              NUM_ALTERATIONS_FOR_NEW_GROUP ||
          group.deepEquals(lastGroup)) {
        groupAlreadyMade = true;
      }
    }
    if (groupsProposedByOthers.any((element) => element.deepEquals(group))) {
      groupAlreadyMade = true;
    }

    if (!groupAlreadyMade) {
      final randomProposal = randomChoice(dumbGroupProposals);

      final conversationId = await maybeGetConversationWith([
        ...group,
      ], resendCount);
      if (conversationId != null) {
        await maybeSendMessage(randomProposal, conversationId, resendCount);
      }

      prevGroups.add(group);
    }

    if (!proposeGroupCompleter!.isCompleted) {
      proposeGroupCompleter!.complete();
    }
  }

  //Adding this to avoid async issues
  Completer<void>? announceAlterationsCompleter;

  Future<void> alterGroup(
    CommunityEvaluation group,
    int resendCount, {
    bool stateReason = true,
  }) async {
    //Can't alter a group that doesn't exist
    if (lastGroup == null || lastGroup!.length < 2) {
      return;
    }

    if (announceAlterationsCompleter != null) {
      await announceAlterationsCompleter!.future;
    }

    announceAlterationsCompleter = Completer<void>();

    //Add a player to most recent group
    final playersNotInPrev = <String>[];
    for (final player in group.s) {
      if (!(lastGroup?.contains(player) ?? false)) {
        playersNotInPrev.add(player);
      }
    }

    //Remove a player from most recent group
    final playersNotInGroup = <String>[];
    for (final player in lastGroup ?? <String>{}) {
      if (!group.s.contains(player)) {
        playersNotInGroup.add(player);
      }
    }

    final totalAlterations =
        (playersNotInPrev.length) + (playersNotInGroup.length);
    if (totalAlterations != 0 &&
        totalAlterations < NUM_ALTERATIONS_FOR_NEW_GROUP &&
        lastGroup != null &&
        !groupsProposedByOthers.any((element) => element.deepEquals(group.s))) {
      //Add and drop players
      if (playersNotInGroup.isNotEmpty && playersNotInPrev.isNotEmpty) {
        final subGroup = group.s.where(
          (player) => !playersNotInPrev.contains(player),
        );

        final conversationIdOfSubGroup = await maybeGetConversationWith([
          ...subGroup,
        ], resendCount);
        if (conversationIdOfSubGroup != null) {
          if (playersNotInPrev.isNotEmpty) {
            final reason = getReasonForGroupAlteration(
              convertToEvalWithChat(group),
              true,
            );
            final message =
                'Replace ${getStringOfPlayers(playersNotInGroup)} with ${getStringOfPlayers(playersNotInPrev)}?';
            if (!announcedAlterations.contains(message.toLowerCase())) {
              await maybeSendMessage(
                message,
                conversationIdOfSubGroup,
                resendCount,
              );
              announcedAlterations.add(message.toLowerCase());
            }

            if (stateReason) {
              await randomWait(3);
              await maybeSendMessage(
                reason,
                conversationIdOfSubGroup,
                resendCount,
              );
            }
          }
        }

        await randomWait(10, minSeconds: 3);
        final conversationIdOfGroup = await maybeGetConversationWith([
          ...group.s,
        ], resendCount);
        if (conversationIdOfGroup != null) {
          if (playersNotInPrev.isNotEmpty) {
            final message =
                '${getStringOfPlayers(playersNotInPrev)} would you like to join our group';
            if (!announcedAlterations.contains(message.toLowerCase())) {
              await maybeSendMessage(
                message,
                conversationIdOfGroup,
                resendCount,
              );
              announcedAlterations.add(message.toLowerCase());
            }
          }
        }
      } else {
        //Adding players
        final conversationIdOfPrevGroup = await maybeGetConversationWith([
          ...lastGroup!,
        ], resendCount);
        if (conversationIdOfPrevGroup != null) {
          if (playersNotInPrev.isNotEmpty) {
            final reason = getReasonForGroupAlteration(
              convertToEvalWithChat(group),
              true,
            );
            final message =
                'Add ${getStringOfPlayers(playersNotInPrev)} to the group?';

            if (!announcedAlterations.contains(message.toLowerCase())) {
              await maybeSendMessage(
                message,
                conversationIdOfPrevGroup,
                resendCount,
              );
              announcedAlterations.add(message.toLowerCase());
            }
            if (stateReason) {
              await randomWait(3);
              await maybeSendMessage(
                reason,
                conversationIdOfPrevGroup,
                resendCount,
              );
            }
          }

          await randomWait(10, minSeconds: 3);
          final conversationIdOfGroup = await maybeGetConversationWith([
            ...group.s,
          ], resendCount);
          if (conversationIdOfGroup != null) {
            if (playersNotInPrev.isNotEmpty) {
              final message =
                  '${getStringOfPlayers(playersNotInPrev)} would you like to join our group';

              if (!announcedAlterations.contains(message.toLowerCase())) {
                await maybeSendMessage(
                  message,
                  conversationIdOfGroup,
                  resendCount,
                );
                announcedAlterations.add(message.toLowerCase());
              }
            }
          }
        }

        //Dropping players
        final conversationIdOfNewGroup = await maybeGetConversationWith([
          ...group.s,
        ], resendCount);
        if (conversationIdOfNewGroup != null) {
          if (playersNotInGroup.isNotEmpty) {
            final reason = getReasonForGroupAlteration(
              convertToEvalWithChat(group),
              false,
            );
            final message =
                'Drop ${getStringOfPlayers(playersNotInGroup)} from the group?';

            if (!announcedAlterations.contains(message.toLowerCase())) {
              await maybeSendMessage(
                message,
                conversationIdOfNewGroup,
                resendCount,
              );
              announcedAlterations.add(message.toLowerCase());
            }

            if (stateReason) {
              await randomWait(3);
              await maybeSendMessage(
                reason,
                conversationIdOfNewGroup,
                resendCount,
              );
            }
          }
        }
      }
    }

    if (!announceAlterationsCompleter!.isCompleted) {
      announceAlterationsCompleter!.complete();
    }
  }

  String getReasonForGroupAlteration(
    CommunityEvaluationWithChat group,
    bool isAdd,
  ) {
    final mostRecentCommEval = getCommunityEval(lastGroup);

    final reasoningMap = {
      //TODO: explain these things better
      //NOTE: This should match the listOfReasoning at the top
      'It will make us more modular': group.getModularityDifference(
        mostRecentCommEval,
        activeGenes!,
      ),
      isAdd ? 'I like them' : "I don't like them": group
          .getCentralityDifference(mostRecentCommEval, activeGenes!),
      isAdd ? 'It will make us stronger' : 'We will be a better size': group
          .getCollectiveStrengthDifference(mostRecentCommEval, activeGenes!),
      'We are more connected': group.getFamiliarityDifference(
        mostRecentCommEval,
        activeGenes!,
      ),
      isAdd ? 'We are all giving to each other' : 'They are not giving enough':
          group.getProsocialDifference(mostRecentCommEval, activeGenes!),
      isAdd
          ? 'They want to be in our group'
          : "They don't want to be in our group": group
          .getChatAgreementDifference(mostRecentCommEval, activeGenes!),
      isAdd ? 'I trust them' : "I don't trust them": group.getTrustDifference(
        mostRecentCommEval,
        activeGenes!,
      ),
    };

    if (reasoningMap.values.every((element) => element.isNegative)) {
      return 'Because I say so';
    }

    final reason = reasoningMap.entries.reduce(
      (previousValue, element) =>
          previousValue.value < element.value ? element : previousValue,
    );

    return reason.key;
  }

  CommunityEvaluationWithChat? getCommunityEval(Set<String>? community) {
    if (community == null) {
      return null;
    }

    final players = currentRound.info.playerPopularities.keys.toSet();

    final aPos = computeAdjacency();
    final aNeg = computeNegAdjacency();

    var curCommSize = 0.0;
    for (final player in lastGroup ?? {}) {
      curCommSize += currentRound.info.playerPopularities[player]!;
    }
    curCommSize /= currentRound.info.playerPopularities.values.sum;

    final determineCommunitiesResult = determineCommunities(
      convertComToIdx([
        community,
      ], currentRound.info.playerPopularities.keys.toList()),
      [community],
      0,
      aPos,
      aNeg,
    );
    final m = determineCommunitiesResult[2] as double;

    return CommunityEvaluationWithChat(
      s: community,
      modularity: m,
      centrality: getCentrality(
        community,
        currentRound.info.playerPopularities,
      ),
      collectiveStrength: getCollectiveStrength(
        currentRound.info.playerPopularities,
        community,
        curCommSize,
      ),
      familiarity: getFamiliarity(
        community,
        players,
        transposeMap(removeIntrinsic(currentRound.info.playerInfluences)),
      ),
      prosocial: getIngroupAntisocial(community),
      trust: getTrust(community),
      chatAgreement: getChatAgreement(community),
      isCurrentCommunity: getIsCurrentCommunity(community),
    );
  }

  Future<void> tellGroupWhoAttackedYou(
    Map<String, int> transactions,
    Set<String> group,
  ) async {
    final attackedBy = getAttackers();

    if (attackedBy.isNotEmpty) {
      final conversationId = await getConversationWith(group.toList());
      if (conversationId != null) {
        await sendMessage(
          'I was attacked by ${getStringOfPlayers(attackedBy)}',
          conversationId,
        );
        if (transactions[myPlayerName] == currentRound.info.playerTokens) {
          await sendMessage(
            "I'm keeping this round to protect myself",
            conversationId,
          );
        }
      }

      final attackers = await getConversationWith(attackedBy);
      if (attackers != null) {
        await sendMessage('Ow', attackers);
      }
    }
  }

  Future<void> tellGroupWhoLied(Set<String> group) async {
    final conversationId = await getConversationWith(group.toList());
    if (conversationId != null) {
      for (final player in currentRound.info.groupMembers) {
        if ((prevAllocationsStatedByOthers[player] ?? 0) >
                (currentRound.info.tokensReceived?[player] ?? 0) &&
            (currentRound.info.tokensReceived?[player] ?? 0) >= 0) {
          await sendMessage(
            '$player did not give me ${prevAllocationsStatedByOthers[player]} like they said',
            conversationId,
          );
        }
      }
    }
  }

  Completer<void>? announceFearCompleter;

  Future<void> anounceFear(Set<String> group, int resendCount) async {
    final conversationId = await maybeGetConversationWith(
      group.toList(),
      resendCount,
    );

    if (announceFearCompleter != null) {
      await announceFearCompleter!.future;
    }

    announceFearCompleter = Completer<void>();

    if (conversationId != null) {
      final unannouncedFear = getFearedPlayers(group);

      for (final message in announcedFear) {
        final playersInMessage = getMentionedPlayerNames(
          IdentifiedChatMessage(from: '', body: message, time: DateTime.now()),
        );

        unannouncedFear.removeWhere(playersInMessage.contains);
      }

      if (unannouncedFear.isNotEmpty) {
        final message = 'I am afraid of ${getStringOfPlayers(unannouncedFear)}';
        final sent = await maybeSendMessage(
          message,
          conversationId,
          resendCount,
        );
        if (sent) {
          announcedFear.add(message);
        }
      }
    }

    if (!announceFearCompleter!.isCompleted) {
      announceFearCompleter!.complete();
    }
  }

  List<String> getFearedPlayers(Set<String> myGroup) {
    final fearedPlayers = <String>[];

    // I'm afraid of players who have a fear value greater than my fear threshold
    for (final player in currentRound.info.groupMembers) {
      if (fear[player]! > activeGenes!.fearThreshold / 100) {
        fearedPlayers.add(player);
      }
    }

    // I'm afraid of everyone in a group if the group's fear value is greater than my fear threshold
    for (final group in groupFear.entries) {
      if (group.value > activeGenes!.fearThreshold / 100) {
        fearedPlayers.addAll(group.key);
      }
    }

    // I'm not afraid of people in my group
    fearedPlayers.removeWhere(myGroup.contains);

    return fearedPlayers.toSet().toList();
  }

  Completer<void>? announcePotentialAttacksCompleter;

  Future<void> announcePotentialAttacks(
    Set<String> group,
    int resendCount,
  ) async {
    if (announcePotentialAttacksCompleter != null) {
      await announcePotentialAttacksCompleter!.future;
    }

    announcePotentialAttacksCompleter = Completer<void>();

    final conversationId = await maybeGetConversationWith(
      group.toList(),
      resendCount,
    );

    if (conversationId != null) {
      final potentialAttacks =
          envisionFearAttack(
            currentRound.info.playerTokens,
            group,
          ).map((e) => e.$1).toSet();
      final attacksAlreadyProposed = <String>[];

      for (final message in announcedPotentialAttacks) {
        final playersInMessage = getMentionedPlayerNames(
          IdentifiedChatMessage(from: '', body: message, time: DateTime.now()),
        );

        potentialAttacks.removeWhere(playersInMessage.contains);
      }

      for (final attack in proposedAttacks) {
        final playersInMessage = getMentionedPlayerNames(
          IdentifiedChatMessage(from: '', body: attack, time: DateTime.now()),
        );

        attacksAlreadyProposed.addAll(playersInMessage);
      }

      // if the attack has been proposed by someone else, just say you are attacking
      if (potentialAttacks.isNotEmpty) {
        if (attacksAlreadyProposed.isNotEmpty) {
          final willAttack = potentialAttacks.where(
            attacksAlreadyProposed.contains,
          );

          final message =
              'I will attack ${getStringOfPlayers(willAttack.toList())}';
          if (!announcedPotentialAttacks.contains(message)) {
            final sent = await maybeSendMessage(
              message,
              conversationId,
              resendCount,
            );
            if (sent) announcedPotentialAttacks.add(message);
          }

          potentialAttacks.removeWhere(willAttack.contains);
        }
      }

      //otherwise, propose the attack
      if (potentialAttacks.isNotEmpty) {
        final message =
            'Attack ${getStringOfPlayers(potentialAttacks.toList())}?';
        if (!announcedPotentialAttacks.contains(message)) {
          await maybeSendMessage(message, conversationId, resendCount);
          announcedPotentialAttacks.add(message);
          proposedAttacks.add(message);
        }
      }
    }

    if (!announcePotentialAttacksCompleter!.isCompleted) {
      announcePotentialAttacksCompleter!.complete();
    }
  }

  //Adding this to avoid async issues
  Completer<void>? announceAttackCompleter;

  Future<void> announceAttacks(
    Set<String> group,
    Map<String, int> attackAlloc,
    int resendCount,
  ) async {
    if (announceAttackCompleter != null) {
      await announceAttackCompleter!.future;
    }

    final rawAttacking =
        attackAlloc.entries
            .where((element) => element.value < 0)
            .map((e) => e.key)
            .toList();
    final rawAttackingAmounts =
        attackAlloc.entries
            .where((element) => element.value < 0)
            .map((e) => e.value.abs())
            .toList();

    final attacking = <String>[];
    final attackingAmounts = <String>[];
    for (var i = 0; i < rawAttacking.length; i++) {
      // if (announcedAttacks[rawAttacking[i]] != rawAttackingAmounts.elementAt(i)) {
      attacking.add(rawAttacking[i]);
      attackingAmounts.add(rawAttackingAmounts[i].toString());
      // }
    }

    if (attacking.isNotEmpty) {
      final conversationId = await maybeGetConversationWith([
        ...group,
      ], resendCount);
      if (conversationId != null) {
        announceAttackCompleter = Completer<void>();
        final message =
            'I am attacking ${getStringOfPlayers(attacking)} with ${getStringOfPlayers(attackingAmounts.toList())}';
        if (announcedAttacks.any((element) => element == message)) {
          final messageSuccess = await maybeSendMessage(
            'I am attacking ${getStringOfPlayers(attacking)} with ${getStringOfPlayers(attackingAmounts.toList())}',
            conversationId,
            resendCount,
          );

          if (messageSuccess) {
            logfile?.writeAsStringSync(
              'I, $myPlayerName, am attacking ${getStringOfPlayers(attacking)} with ${getStringOfPlayers(attackingAmounts.toList())}\n',
              mode: FileMode.append,
            );

            announcedAttacks.add(message);

            // for (final player in attacking) {
            // announcedAttacks[player] = attackAlloc[player]!.abs();
            // }
          }
        }
        announceAttackCompleter!.complete();
      }
    }
  }

  //Adding this to avoid async issues
  Completer<void>? announceAllocationsCompleter;

  Future<void> announceAllocations(
    Map<String, int> transactionVec,
    Set<String> group,
    int resendCount,
  ) async {
    if (announceAllocationsCompleter != null) {
      await announceAllocationsCompleter!.future;
    }

    announceAllocationsCompleter = Completer<void>();

    final groupAllocations = <String, int>{};
    for (final allocation in transactionVec.entries) {
      if (resendCount != resendCounter) return;

      if (allocation.value > 0) {
        if (group.contains(allocation.key)) {
          groupAllocations.addEntries([allocation]);
        } else if (allocation.key != myPlayerName) {
          final conversationId = await maybeGetConversationWith([
            allocation.key,
          ], resendCount);

          if (conversationId != null &&
              announcedTransactions[allocation.key] != allocation.value) {
            if (allocation.value == lastTransactions[allocation.key]) {
              await maybeSendMessage(
                'Same as last round',
                conversationId,
                resendCount,
              );
              announcedTransactions[allocation.key] = allocation.value;
            } else {
              await maybeSendMessage(
                'Sending you ${allocation.value}',
                conversationId,
                resendCount,
              );
              announcedTransactions[allocation.key] = allocation.value;
            }
          }
        }
      } else if (allocation.value == 0) {
        if ((announcedTransactions[allocation.key] ?? 0) > 0) {
          final conversationId = await maybeGetConversationWith([
            allocation.key,
          ], resendCount);

          if (conversationId != null &&
              announcedTransactions[allocation.key] != allocation.value) {
            await maybeSendMessage(
              "Sorry, I'm actually sending you 0",
              conversationId,
              resendCount,
            );
            announcedTransactions[allocation.key] = allocation.value;
          }
        }
      }
    }

    //tell everyone in the group what you are giving to who
    groupAllocations.remove(myPlayerName);
    while (groupAllocations.isNotEmpty) {
      if (resendCount != resendCounter) return;

      await randomWait(5, minSeconds: 2);
      final conversationId = await maybeGetConversationWith([
        ...group,
      ], resendCount);
      final amount = groupAllocations.entries.first.value;
      final playersGettingAmount =
          groupAllocations.entries
              .where((element) => element.value == amount)
              .map((e) => e.key)
              .toList();

      if (playersGettingAmount.every(
        (element) => announcedTransactions[element] == amount,
      )) {
        groupAllocations.removeWhere(
          (key, value) => playersGettingAmount.contains(key),
        );
        continue;
      }

      //if giving the same amount to everyone in the group
      final groupCopy = Set<String>.from(group);
      if (playersGettingAmount.deepEquals(groupCopy..remove(myPlayerName))) {
        final conversationId = await maybeGetConversationWith([
          ...group,
        ], resendCount);

        if (conversationId != null) {
          if (playersGettingAmount.every(
            (player) => amount == lastTransactions[player],
          )) {
            await maybeSendMessage(
              'Same as last round',
              conversationId,
              resendCount,
            );
          } else {
            if (group.length > 2) {
              await maybeSendMessage(
                'Sending you each $amount',
                conversationId,
                resendCount,
              );
            } else {
              await maybeSendMessage(
                'Sending you $amount',
                conversationId,
                resendCount,
              );
            }
          }
        }
      }
      //Make sure not to send a message about what you are keeping
      else if (conversationId != null &&
          !(playersGettingAmount.length == 1 &&
              playersGettingAmount[0] == myPlayerName)) {
        await maybeSendMessage(
          'Sending $amount to ${getStringOfPlayers(playersGettingAmount)}',
          conversationId,
          resendCount,
        );
      }

      for (final element in playersGettingAmount) {
        announcedTransactions[element] = amount;
      }
      groupAllocations.removeWhere(
        (key, value) => playersGettingAmount.contains(key),
      );
    }

    announceAllocationsCompleter!.complete();
  }

  // Causes the bot to state observations about the groups that are present and the relative power of the groups.
  // - [group] the group that the bot is in
  // - [passedInConversationId] the conversation id to use, if not provided, the bot will use the id of their own group
  Future<void> stateObservations(
    CommunityEvaluation group,
    String? passedInConversationId,
  ) async {
    if (currentRound.info.round < 2) {
      return;
    }
    final conversationId =
        passedInConversationId ?? await getConversationWith([...group.s]);
    final communityComparisonMap = <Set<String>, double>{};
    if (conversationId != null) {
      for (final community in observedCommunities) {
        if (!group.s.any(community.contains)) {
          await randomWait(3);

          final notGroup =
              '${getStringOfPlayers(community.toList())} is not in a group';
          if (community.length == 1) {
            if (observationsAlreadyMade.entries
                    .firstWhereOrNull(
                      (element) => element.key.deepEquals(community),
                    )
                    ?.value !=
                notGroup) {
              await sendMessage(notGroup, conversationId);
              observationsAlreadyMade.removeWhere(
                (key, value) => key.deepEquals(community),
              );
              observationsAlreadyMade[community] = notGroup;
            }
          } else {
            final difference =
                getPopularityStrength(community) -
                getPopularityStrength(group.s);
            communityComparisonMap[community] = difference;

            final String observation;
            final String namedObservation;
            if (difference > 0) {
              observation = 'They are more powerful than my group';
              namedObservation =
                  '${getStringOfPlayers(community.toList())} are more powerful than my group';
            } else {
              observation = 'We are more powerful than them';
              namedObservation =
                  'We are more powerful than ${getStringOfPlayers(community.toList())}';
            }
            // print('Obs $observationsAlreadyMade');

            // Don't say things that you've already said
            if (observationsAlreadyMade.entries.firstWhereOrNull(
                  (element) => element.key.deepEquals(community),
                ) ==
                null) {
              await sendMessage(
                '${getStringOfPlayers(community.toList())} are a group',
                conversationId,
              );

              observationsAlreadyMade.removeWhere(
                (key, value) => key.deepEquals(community),
              );
              observationsAlreadyMade[community] = observation;
              await sendMessage(observation, conversationId);
            } else if (observationsAlreadyMade.entries
                    .firstWhereOrNull(
                      (element) => element.key.deepEquals(community),
                    )
                    ?.value !=
                namedObservation) {
              observationsAlreadyMade.removeWhere(
                (key, value) => key.deepEquals(community),
              );
              observationsAlreadyMade[community] = namedObservation;
              await sendMessage(namedObservation, conversationId);
            }
          }
        }
      }
      await randomWait(3);

      //Say what group is the most powerful
      if (communityComparisonMap.values.every(
        (element) => element.isNegative,
      )) {
        if (!previousMostPowerful.deepEquals(group.s)) {
          await sendMessage('We are the most powerful group', conversationId);
        }
        previousMostPowerful = group.s;
      } else {
        final mostPowerful = communityComparisonMap.entries.reduce(
          (previousValue, element) =>
              previousValue.value < element.value ? element : previousValue,
        );
        if (!previousMostPowerful.deepEquals(mostPowerful.key)) {
          await sendMessage(
            '${getStringOfPlayers(mostPowerful.key.toList())} ${mostPowerful.key.length == 1 ? 'is the most powerful' : 'are the most powerful group'}',
            conversationId,
          );
        }
        previousMostPowerful = mostPowerful.key;
      }
    }
  }

  double getPopularityStrength(Set<String> s) {
    var strength = 0.0;
    for (final i in s) {
      strength += currentRound.info.playerPopularities[i]!;
    }

    return strength / currentRound.info.playerPopularities.values.sum;
  }

  @override
  CommunityEvaluation envisionCommunities(
    Map<String, Map<String, double>> aPos,
    Map<String, Map<String, double>> aNeg,
    List<Set<int>> communitiesPh1,
    List<Set<int>> communitiesByIndex,
    List<Set<String>> communities,
    double modularity,
  ) {
    observedCommunities = communities;
    final potentialCommunities = <CommunityEvaluation>[];

    var sIdx = findCommunity(communities);

    final popularities = currentRound.info.playerPopularities;
    final players = popularities.keys.toSet();

    var curCommSize = 0.0;
    for (final i in communities[sIdx]) {
      curCommSize += popularities[i]!;
    }
    curCommSize /= popularities.values.sum;

    var c = List<Set<String>>.from(communities).map(Set.from).toList();

    final backup = List<Set<int>>.from(communitiesPh1);
    final determineCommunitiesResult = determineCommunities(
      communitiesByIndex,
      communities,
      sIdx,
      aPos,
      aNeg,
    );
    communitiesPh1 = List.from(backup);

    var s = determineCommunitiesResult[0] as Set<String>;
    final m = determineCommunitiesResult[2] as double;

    final removeMostlyDeadResult = removeMostlyDead(
      s,
      currentRound.info.playerPopularities,
    );
    s = removeMostlyDeadResult.first;
    potentialCommunities.add(
      CommunityEvaluationWithChat(
        s: s,
        modularity: m,
        centrality: getCentrality(s, currentRound.info.playerPopularities),
        collectiveStrength: getCollectiveStrength(
          currentRound.info.playerPopularities,
          s,
          curCommSize,
        ),
        familiarity: getFamiliarity(
          s,
          players,
          transposeMap(removeIntrinsic(currentRound.info.playerInfluences)),
        ),
        prosocial: getIngroupAntisocial(s),
        chatAgreement: getChatAgreement(s),
        trust: getTrust(s),
        isCurrentCommunity: getIsCurrentCommunity(s),
      ),
    );

    // combine with any other group
    for (final i in communities) {
      if (i != s) {
        c = List<Set<String>>.from(communities).map(Set<String>.from).toList();
        c[sIdx] = c[sIdx].union(i);
        if (!alreadyIn(c[sIdx], potentialCommunities)) {
          c.remove(i);
          final determineCommunitiesResult = determineCommunities(
            convertComToIdx(
              c.cast(),
              currentRound.info.playerPopularities.keys.toList(),
            ),
            c.cast(),
            findCommunity(c.cast()),
            aPos,
            aNeg,
          );
          var s = determineCommunitiesResult[0] as Set<String>;
          final m = determineCommunitiesResult[2] as double;
          final removeMostlyDeadResult = removeMostlyDead(
            s,
            currentRound.info.playerPopularities,
          );
          s = removeMostlyDeadResult.first;

          potentialCommunities.add(
            CommunityEvaluationWithChat(
              s: s,
              modularity: m,
              centrality: getCentrality(
                s,
                currentRound.info.playerPopularities,
              ),
              collectiveStrength: getCollectiveStrength(
                currentRound.info.playerPopularities,
                s,
                curCommSize,
              ),
              familiarity: getFamiliarity(
                s,
                players,
                transposeMap(
                  removeIntrinsic(currentRound.info.playerInfluences),
                ),
              ),
              prosocial: getIngroupAntisocial(s),
              chatAgreement: getChatAgreement(s),
              trust: getTrust(s),
              isCurrentCommunity: getIsCurrentCommunity(s),
            ),
          );
        }
      }
    }

    // move to a different group
    for (final i in communities) {
      if (i != s) {
        c = List<Set<String>>.from(communities).map(Set<String>.from).toList();
        c[communities.indexOf(i)].add(myPlayerName);
        if (!alreadyIn(c[communities.indexOf(i)], potentialCommunities)) {
          c[sIdx].remove(myPlayerName);
          final determineCommunitiesResult = determineCommunities(
            convertComToIdx(c.cast(), players.toList()),
            c.cast(),
            communities.indexOf(i),
            aPos,
            aNeg,
          );
          var s = determineCommunitiesResult[0] as Set<String>;
          final m = determineCommunitiesResult[2] as double;
          final removeMostlyDeadResult = removeMostlyDead(
            s,
            currentRound.info.playerPopularities,
          );
          s = removeMostlyDeadResult.first;

          potentialCommunities.add(
            CommunityEvaluationWithChat(
              s: s,
              modularity: m,
              centrality: getCentrality(
                s,
                currentRound.info.playerPopularities,
              ),
              collectiveStrength: getCollectiveStrength(
                currentRound.info.playerPopularities,
                s,
                curCommSize,
              ),
              familiarity: getFamiliarity(
                s,
                players,
                transposeMap(
                  removeIntrinsic(currentRound.info.playerInfluences),
                ),
              ),
              prosocial: getIngroupAntisocial(s),
              chatAgreement: getChatAgreement(s),
              trust: getTrust(s),
              isCurrentCommunity: getIsCurrentCommunity(s),
            ),
          );
        }
      }
    }

    // add a member from another group
    for (final i in players) {
      if (!communities[sIdx].contains(i)) {
        c = List<Set<String>>.from(communities).map(Set<String>.from).toList();
        for (final s in c) {
          if (s.contains(i)) {
            s.remove(i);
            break;
          }
        }
        c[sIdx].add(i);
        if (!alreadyIn(c[sIdx], potentialCommunities)) {
          final determineCommunitiesResult = determineCommunities(
            convertComToIdx(
              c.cast(),
              currentRound.info.playerPopularities.keys.toList(),
            ),
            c.cast(),
            findCommunity(c.cast()),
            aPos,
            aNeg,
          );
          var s = determineCommunitiesResult[0] as Set<String>;
          final m = determineCommunitiesResult[2] as double;
          final removeMostlyDeadResult = removeMostlyDead(
            s,
            currentRound.info.playerPopularities,
          );
          s = removeMostlyDeadResult.first;

          potentialCommunities.add(
            CommunityEvaluationWithChat(
              s: s,
              modularity: m,
              centrality: getCentrality(
                s,
                currentRound.info.playerPopularities,
              ),
              collectiveStrength: getCollectiveStrength(
                currentRound.info.playerPopularities,
                s,
                curCommSize,
              ),
              familiarity: getFamiliarity(
                s,
                players,
                transposeMap(
                  removeIntrinsic(currentRound.info.playerInfluences),
                ),
              ),
              prosocial: getIngroupAntisocial(s),
              chatAgreement: getChatAgreement(s),
              trust: getTrust(s),
              isCurrentCommunity: getIsCurrentCommunity(s),
            ),
          );
        }
      }
    }

    //subtract a member from the group (that isn't player_idx)
    for (final i in communities[sIdx]) {
      if (i != myPlayerName) {
        c = List<Set<String>>.from(communities).map(Set<String>.from).toList();
        c[sIdx].remove(i);
        if (!alreadyIn(c[sIdx], potentialCommunities)) {
          c.add(<String>{i});
          final determineCommunitiesResult = determineCommunities(
            convertComToIdx(c.cast(), players.toList()),
            c.cast(),
            sIdx,
            aPos,
            aNeg,
          );
          var s = determineCommunitiesResult[0] as Set<String>;
          final m = determineCommunitiesResult[2] as double;
          final removeMostlyDeadResult = removeMostlyDead(
            s,
            currentRound.info.playerPopularities,
          );
          s = removeMostlyDeadResult.first;

          potentialCommunities.add(
            CommunityEvaluationWithChat(
              s: s,
              modularity: m,
              centrality: getCentrality(
                s,
                currentRound.info.playerPopularities,
              ),
              collectiveStrength: getCollectiveStrength(
                currentRound.info.playerPopularities,
                s,
                curCommSize,
              ),
              familiarity: getFamiliarity(
                s,
                players,
                transposeMap(
                  removeIntrinsic(currentRound.info.playerInfluences),
                ),
              ),
              prosocial: getIngroupAntisocial(s),
              chatAgreement: getChatAgreement(s),
              trust: getTrust(s),
              isCurrentCommunity: getIsCurrentCommunity(s),
            ),
          );
        }
      }
    }

    final s2Idx = findCommunity(
      convertComFromIdx(communitiesPh1, players.toList()),
    );
    final communitiesPh1ByPlayer = convertComFromIdx(
      communitiesPh1,
      players.toList(),
    );
    // if (sIdx != s2Idx) {
    if (!communities[sIdx].deepEquals(
      communitiesPh1ByPlayer[s2Idx],
      ignoreOrder: true,
    )) {
      sIdx = s2Idx;
      // put in the original with combined other groups
      c =
          List<Set<String>>.from(
            communitiesPh1ByPlayer,
          ).map(Set<String>.from).toList();
      final determineCommunitiesResult = determineCommunities(
        convertComToIdx(
          c.cast(),
          currentRound.info.playerPopularities.keys.toList(),
        ),
        c.cast(),
        sIdx,
        aPos,
        aNeg,
      );
      var s = determineCommunitiesResult[0] as Set<String>;
      final m = determineCommunitiesResult[2] as double;
      final removeMostlyDeadResult = removeMostlyDead(
        s,
        currentRound.info.playerPopularities,
      );
      s = removeMostlyDeadResult.first;
      potentialCommunities.add(
        CommunityEvaluationWithChat(
          s: s,
          modularity: m,
          centrality: getCentrality(s, currentRound.info.playerPopularities),
          collectiveStrength: getCollectiveStrength(
            currentRound.info.playerPopularities,
            s,
            curCommSize,
          ),
          familiarity: getFamiliarity(
            s,
            players,
            transposeMap(removeIntrinsic(currentRound.info.playerInfluences)),
          ),
          prosocial: getIngroupAntisocial(s),
          chatAgreement: getChatAgreement(s),
          trust: getTrust(s),
          isCurrentCommunity: getIsCurrentCommunity(s),
        ),
      );

      // print('potential communities');
      // for (final com in potentialCommunities) {
      //   com.printCom();
      // }

      // combine with any other group
      for (final i in communitiesPh1ByPlayer) {
        if (i != s) {
          c =
              List<Set<String>>.from(
                communitiesPh1ByPlayer,
              ).map(Set<String>.from).toList();
          c[sIdx] = c[sIdx].union(i);
          if (!alreadyIn(c[sIdx], potentialCommunities)) {
            c.remove(i);
            final determineCommunitiesResult = determineCommunities(
              convertComToIdx(
                c.cast(),
                currentRound.info.playerPopularities.keys.toList(),
              ),
              c.cast(),
              findCommunity(c.cast()),
              aPos,
              aNeg,
            );
            var s = determineCommunitiesResult[0] as Set<String>;
            final m = determineCommunitiesResult[2] as double;
            final removeMostlyDeadResult = removeMostlyDead(
              s,
              currentRound.info.playerPopularities,
            );
            s = removeMostlyDeadResult.first;

            potentialCommunities.add(
              CommunityEvaluationWithChat(
                s: s,
                modularity: m,
                centrality: getCentrality(
                  s,
                  currentRound.info.playerPopularities,
                ),
                collectiveStrength: getCollectiveStrength(
                  currentRound.info.playerPopularities,
                  s,
                  curCommSize,
                ),
                familiarity: getFamiliarity(
                  s,
                  players,
                  transposeMap(
                    removeIntrinsic(currentRound.info.playerInfluences),
                  ),
                ),
                prosocial: getIngroupAntisocial(s),
                chatAgreement: getChatAgreement(s),
                trust: getTrust(s),
                isCurrentCommunity: getIsCurrentCommunity(s),
              ),
            );
          }
        }
      }

      // move to a different group
      for (final i in communitiesPh1ByPlayer) {
        if (i != s) {
          c =
              List<Set<String>>.from(
                communitiesPh1ByPlayer,
              ).map(Set<String>.from).toList();
          c[communitiesPh1ByPlayer.indexOf(i)].add(myPlayerName);
          if (!alreadyIn(
            c[communitiesPh1ByPlayer.indexOf(i)],
            potentialCommunities,
          )) {
            c[sIdx].remove(myPlayerName);
            final determineCommunitiesResult = determineCommunities(
              convertComToIdx(c.cast(), players.toList()),
              c.cast(),
              communitiesPh1ByPlayer.indexOf(i),
              aPos,
              aNeg,
            );
            var s = determineCommunitiesResult[0] as Set<String>;
            final m = determineCommunitiesResult[2] as double;
            final removeMostlyDeadResult = removeMostlyDead(
              s,
              currentRound.info.playerPopularities,
            );
            s = removeMostlyDeadResult.first;

            potentialCommunities.add(
              CommunityEvaluationWithChat(
                s: s,
                modularity: m,
                centrality: getCentrality(
                  s,
                  currentRound.info.playerPopularities,
                ),
                collectiveStrength: getCollectiveStrength(
                  currentRound.info.playerPopularities,
                  s,
                  curCommSize,
                ),
                familiarity: getFamiliarity(
                  s,
                  players,
                  transposeMap(
                    removeIntrinsic(currentRound.info.playerInfluences),
                  ),
                ),
                prosocial: getIngroupAntisocial(s),
                chatAgreement: getChatAgreement(s),
                trust: getTrust(s),
                isCurrentCommunity: getIsCurrentCommunity(s),
              ),
            );
          }
        }
      }

      // # add a member from another group
      for (final i in players) {
        if (!communitiesPh1ByPlayer[sIdx].contains(i)) {
          c =
              List<Set<String>>.from(
                communitiesPh1ByPlayer,
              ).map(Set<String>.from).toList();
          for (final s in c) {
            if (s.contains(i)) {
              s.remove(i);
              break;
            }
          }
          c[sIdx].add(i);
          if (!alreadyIn(c[sIdx], potentialCommunities)) {
            final determineCommunitiesResult = determineCommunities(
              convertComToIdx(
                c.cast(),
                currentRound.info.playerPopularities.keys.toList(),
              ),
              c.cast(),
              findCommunity(c.cast()),
              aPos,
              aNeg,
            );
            var s = determineCommunitiesResult[0] as Set<String>;
            final m = determineCommunitiesResult[2] as double;
            final removeMostlyDeadResult = removeMostlyDead(
              s,
              currentRound.info.playerPopularities,
            );
            s = removeMostlyDeadResult.first;

            potentialCommunities.add(
              CommunityEvaluationWithChat(
                s: s,
                modularity: m,
                centrality: getCentrality(
                  s,
                  currentRound.info.playerPopularities,
                ),
                collectiveStrength: getCollectiveStrength(
                  currentRound.info.playerPopularities,
                  s,
                  curCommSize,
                ),
                familiarity: getFamiliarity(
                  s,
                  players,
                  transposeMap(
                    removeIntrinsic(currentRound.info.playerInfluences),
                  ),
                ),
                prosocial: getIngroupAntisocial(s),
                chatAgreement: getChatAgreement(s),
                trust: getTrust(s),
                isCurrentCommunity: getIsCurrentCommunity(s),
              ),
            );
          }
        }
      }

      //subtract a member from the group (that isn't player_idx)
      for (final i in communitiesPh1ByPlayer[sIdx]) {
        if (i != myPlayerName) {
          c =
              List<Set<String>>.from(
                communitiesPh1ByPlayer,
              ).map(Set<String>.from).toList();
          c[sIdx].remove(i);
          if (!alreadyIn(c[sIdx], potentialCommunities)) {
            c.add(<String>{i});
            final determineCommunitiesResult = determineCommunities(
              convertComToIdx(c.cast(), players.toList()),
              c.cast(),
              sIdx,
              aPos,
              aNeg,
            );
            var s = determineCommunitiesResult[0] as Set<String>;
            final m = determineCommunitiesResult[2] as double;
            final removeMostlyDeadResult = removeMostlyDead(
              s,
              currentRound.info.playerPopularities,
            );
            s = removeMostlyDeadResult.first;

            potentialCommunities.add(
              CommunityEvaluationWithChat(
                s: s,
                modularity: m,
                centrality: getCentrality(
                  s,
                  currentRound.info.playerPopularities,
                ),
                collectiveStrength: getCollectiveStrength(
                  currentRound.info.playerPopularities,
                  s,
                  curCommSize,
                ),
                familiarity: getFamiliarity(
                  s,
                  players,
                  transposeMap(
                    removeIntrinsic(currentRound.info.playerInfluences),
                  ),
                ),
                prosocial: getIngroupAntisocial(s),
                chatAgreement: getChatAgreement(s),
                trust: getTrust(s),
                isCurrentCommunity: getIsCurrentCommunity(s),
              ),
            );
          }
        }
      }
    }
    var minMod = modularity;
    for (final c in potentialCommunities) {
      if (c.modularity < minMod) {
        minMod = c.modularity;
      }
    }

    var elegir = potentialCommunities[0];

    var mx = -99999.0;
    for (final c in potentialCommunities) {
      if (modularity == minMod) {
        c.modularity = 1.0;
      } else {
        c.modularity = (c.modularity - minMod) / (modularity - minMod);
      }
      c.computeScore(activeGenes!); //, coalitionTarget);
      // print('SCORE');
      // c.printCom();
      if (c.score > mx) {
        elegir = c;
        mx = c.score;
      }
    }

    meImporta = {for (final player in players) player: 0};
    for (final i in elegir.s) {
      var mejor = 1.0;
      if (i != myPlayerName) {
        for (final comm in potentialCommunities) {
          if (!comm.s.contains(i)) {
            mejor = min(mejor, (elegir.score - comm.score) / elegir.score);
          }
        }
      }

      meImporta[i] = mejor;
    }
    // print('elegir');
    // elegir.printCom();

    return elegir;
  }

  @override
  CommunityEvaluation randomSelections(
    Set<String> playerSet,
    Map<String, double> popularities,
  ) {
    final totalPop = popularities.values.sum;

    // If the bot is already in a group, stick to it
    if (nextGroup != null && nextGroup!.isNotEmpty) {
      return CommunityEvaluation(
        s: nextGroup!,
        centrality: 0,
        collectiveStrength: 0,
        familiarity: 0,
        modularity: 0,
        prosocial: 0,
      );
    }

    // // On the first round, if others proposed a group, choose one of those to stick to that meets the coalition target
    // if (groupsProposedByOthers.isNotEmpty) {
    //   for (final group in groupsProposedByOthers) {
    //     final popOfGroup = group.map((e) => popularities[e]!).sum;
    //     if ((popOfGroup / totalPop) < coalitionTarget) {
    //       return CommunityEvaluation(
    //           s: group,
    //           centrality: 0,
    //           collectiveStrength: 0,
    //           familiarity: 0,
    //           modularity: 0,
    //           prosocial: 0);
    //     }
    //   }
    // }

    //On the first round, if others proposed a group, randomly choose the best one of those to stick to
    if (groupsProposedByOthers.isNotEmpty) {
      final bestGroup = groupsProposedByOthers.fold(
        ((nextGroup ?? {}).isNotEmpty)
            ? nextGroup
            : groupsProposedByOthers.first,
        (previousValue, element) =>
            (getCommunityEval(previousValue)!.computeScore(activeGenes!) <
                    getCommunityEval(element)!.computeScore(activeGenes!))
                ? element
                : previousValue,
      );

      return getCommunityEval(bestGroup)!;
    }

    //Otherwise, create a group of random players
    final players = Set<String>.from(playerSet);
    players.remove(myPlayerName);

    final s = {myPlayerName};

    var pop = popularities[myPlayerName]!;

    while ((pop / totalPop) < coalitionTarget) {
      final String sel;
      if (USE_RANDOM) {
        sel = randomChoice(players);
      } else {
        sel = players.first;
      }

      s.add(sel);

      players.remove(sel);
      pop += popularities[sel]!;
    }

    logfile?.writeAsStringSync(
      'randomSelections $myPlayerName: $s \n',
      mode: FileMode.append,
    );

    return CommunityEvaluation(
      s: s,
      centrality: 0,
      collectiveStrength: 0,
      familiarity: 0,
      modularity: 0,
      prosocial: 0,
    );
  }

  double getChatAgreement(Set<String> group) {
    //Get a sub matrix with only the members of this group
    final chatAgreementForGroup = chatAgreement.entries
        .where((element) => group.contains(element.key))
        .map(
          (e) => MapEntry(
            e.key,
            e.value.entries.where((element) => group.contains(element.key)),
          ),
        );

    //Get the sum of all the entries in this matrix
    final sum = chatAgreementForGroup.fold<double>(
      0,
      (previousValue, element) =>
          previousValue +
          element.value.fold(
            0,
            (previousValue, element) => previousValue + element.value,
          ),
    );

    if (sum == 0) {
      return 0;
    }
    return sum / group.length;
  }

  double getTrust(Set<String> group) {
    var trustSum = 0.0;
    for (final player in group) {
      trustSum += trustMap[player]!;
    }

    return trustSum / group.length;
  }

  bool getIsCurrentCommunity(Set<String> group) {
    return group.deepEquals(nextGroup);
  }

  CommunityEvaluationWithChat convertToEvalWithChat(CommunityEvaluation group) {
    return CommunityEvaluationWithChat(
      s: group.s,
      modularity: group.modularity,
      centrality: group.centrality,
      collectiveStrength: group.collectiveStrength,
      familiarity: group.familiarity,
      prosocial: group.prosocial,
      chatAgreement: getChatAgreement(group.s),
      trust: getTrust(group.s),
      isCurrentCommunity: getIsCurrentCommunity(group.s),
    );
  }

  @override
  double adjustBadMarks(double currentMarks, String player) {
    final accusedAttack = accusedOfAttacking[player]!;
    final accusedLie = accusedOfLying[player]!;

    final accusedAttackSeverity = 1 + accusedAttack * activeGenes!.wAccusations;
    final accusedLieSeverity = 1 + accusedLie * activeGenes!.wAccusations;

    final newMarks = currentMarks * accusedAttackSeverity * accusedLieSeverity;

    return newMarks;
  }

  @override
  Tuple2<String?, int> takeVengeance(int tokensRemaining) {
    final popularities = currentRound.info.playerPopularities;
    final numTokens = currentRound.info.playerTokens;
    final players = popularities.keys;
    final influences = transposeMap(
      removeIntrinsic(currentRound.info.playerInfluences),
    );
    if (popularities[myPlayerName]! <= 0 ||
        activeGenes!.vengeancePriority < 50) {
      return const Tuple2(null, 0);
    }
    final multiplicador = activeGenes!.vengeanceMultiplier / 33.0;
    final vengeanceMax = min(
      numTokens * activeGenes!.vengeanceMax / 100.0,
      tokensRemaining,
    );

    // Magnitude of the attacks stated by A on B weighted by the popularity of A and trust of A
    final attackClaimsMagnitudeMatrix = attackClaims.map(
      (A, value) => MapEntry(
        A,
        value.map((B, tokens) {
          if (tokens == 0 && potentialAttackClaims[A]![B] == 1 && A != B) {
            // If they want to attack assume they'll attack with the same amount as me
            return MapEntry(
              B,
              tokensRemaining * popularities[A]! * trustMap[A]!,
            );
          }

          return MapEntry(B, tokens * popularities[A]! * trustMap[A]!);
        }),
      ),
    );

    // Sum of the magnitude of the attacks stated by everyone on each player
    final attackClaimsMagnitude = {for (final player in players) player: 0.0};
    for (final A in players) {
      for (final B in players) {
        attackClaimsMagnitude[B] =
            attackClaimsMagnitude[B]! + attackClaimsMagnitudeMatrix[A]![B]!;
      }
    }

    // print('attackClaimsMag: $attackClaimsMagnitude');

    final vengeancePossibilities = <List>[];
    for (final player in players) {
      if ((currentRound.info.governmentRoundInfo.governmentPlayerNames
                  ?.contains(player) ??
              false) ||
          player == myPlayerName) {
        continue;
      }

      if (influences[player]![myPlayerName]! < 0 &&
          -influences[player]![myPlayerName]! >
              (.05 * popularities[myPlayerName]!) &&
          influences[player]![myPlayerName]! <
              influences[myPlayerName]![player]! &&
          popularities[player]! > .01) {
        final keepingStrengthW =
            keepingStrength[player]! *
            (popularities[player]! / popularities[myPlayerName]!);
        final theScore =
            numTokens *
            ((influences[player]![myPlayerName]! -
                    influences[myPlayerName]![player]!) /
                (popularities[myPlayerName]! *
                    gameParams.popularityFunctionParams.cSteal *
                    gameParams.popularityFunctionParams.alpha));
        var cantidad =
            (min(
                      -1.0 * (theScore - keepingStrengthW) * multiplicador,
                      vengeanceMax,
                    ) +
                    0.5)
                .toInt();

        if (cantidad <= 0) {
          continue;
        }

        var myWeight = popularities[myPlayerName]! * cantidad;
        var ratio = (myWeight + attackClaimsMagnitude[player]!) / myWeight;

        var gain =
            myWeight -
            (popularities[player]! * keepingStrength[player]! / ratio);

        while (((((gain * ratio) / numTokens) *
                    gameParams.popularityFunctionParams.alpha *
                    gameParams.popularityFunctionParams.cSteal) >
                (popularities[player]! -
                    gameParams.popularityFunctionParams.povertyLine)) &&
            (cantidad > 0)) {
          cantidad -= 1;
          if (cantidad == 0) break;

          myWeight = popularities[myPlayerName]! * cantidad;
          ratio = (myWeight + attackClaimsMagnitude[player]!) / myWeight;

          gain =
              myWeight -
              (popularities[player]! * keepingStrength[player]! / ratio);
        }

        final stealROI =
            (gain * gameParams.popularityFunctionParams.cSteal) /
            (cantidad * popularities[myPlayerName]!);
        final damage =
            (gain / numTokens) *
            gameParams.popularityFunctionParams.cSteal *
            gameParams.popularityFunctionParams.alpha;

        var immGainPerToken =
            (stealROI - ROI) *
            ((cantidad / numTokens) * popularities[myPlayerName]!) *
            gameParams.popularityFunctionParams.alpha;
        immGainPerToken /= cantidad;

        final vengeanceAdvantage = immGainPerToken + damage / cantidad;

        if (vengeanceAdvantage > 0) {
          vengeancePossibilities.add([player, vengeanceAdvantage, cantidad]);
        }
      }
    }

    // random selection
    if (vengeancePossibilities.isNotEmpty) {
      var mag = 0.0;
      for (final i in vengeancePossibilities) {
        mag += i[1]! as double;
      }

      double num;
      if (USE_RANDOM) {
        num = Random().nextDouble();
      } else {
        num = .5;
      }

      var sumr = 0.0;

      for (final i in vengeancePossibilities) {
        sumr += (i[1]! as double) / mag;
        if (num <= sumr) {
          return Tuple2(i[0] as String, i[2] as int);
        }
      }
    }
    return const Tuple2(null, 0);
  }

  /// - agent calculates the advantage if everyone in their group attacks a player (in addition to
  ///how much was already claimed)
  /// - calculate the above for different amounts of tokens?
  /// - if it is advantageous to attack when others are attacking, then suggest the attack in chat
  /// - if someone else suggests an attack, then the agent can calculate the advantage of attacking
  ///that player if everyone in their group attacks that player
  /// - if advantage of that is high, then agree and attack that player
  List<Tuple2<String, double>> envisionVengeance(int tokensRemaining) {
    final popularities = currentRound.info.playerPopularities;
    final numTokens = currentRound.info.playerTokens;
    final players = popularities.keys;
    final influences = transposeMap(
      removeIntrinsic(currentRound.info.playerInfluences),
    );
    if (popularities[myPlayerName]! <= 0 ||
        activeGenes!.vengeancePriority < 50) {
      return [];
    }
    final multiplicador = activeGenes!.vengeanceMultiplier / 33.0;
    final vengeanceMax = min(
      numTokens * activeGenes!.vengeanceMax / 100.0,
      tokensRemaining,
    );

    // Magnitude of the attacks stated by A on B weighted by the popularity of A and trust of A
    var attackClaimsMagnitudeMatrix = attackClaims.map(
      (A, value) => MapEntry(
        A,
        value.map(
          (B, tokens) => MapEntry(B, tokens * popularities[A]! * trustMap[A]!),
        ),
      ),
    );

    // Envision everyone in my group attacking each player
    attackClaimsMagnitudeMatrix = attackClaims.map(
      (A, value) => MapEntry(
        A,
        value.map((B, tokens) {
          if (tokens == 0 && (nextGroup?.contains(A) ?? false)) {
            // assume they'll attack with the same amount as me
            return MapEntry(
              B,
              tokensRemaining * popularities[A]! * trustMap[A]!,
            );
          }

          return MapEntry(B, tokens);
        }),
      ),
    );

    // Sum of the magnitude of the attacks stated by everyone on each player
    final attackClaimsMagnitude = {for (final player in players) player: 0.0};
    for (final A in players) {
      for (final B in players) {
        attackClaimsMagnitude[B] =
            attackClaimsMagnitude[B]! + attackClaimsMagnitudeMatrix[A]![B]!;
      }
    }

    final vengeancePossibilities = <Tuple2<String, double>>[];
    for (final player in players) {
      if ((currentRound.info.governmentRoundInfo.governmentPlayerNames
                  ?.contains(player) ??
              false) ||
          player == myPlayerName) {
        continue;
      }

      if (influences[player]![myPlayerName]! < 0 &&
          -influences[player]![myPlayerName]! >
              (.05 * popularities[myPlayerName]!) &&
          influences[player]![myPlayerName]! <
              influences[myPlayerName]![player]! &&
          popularities[player]! > .01) {
        final keepingStrengthW =
            keepingStrength[player]! *
            (popularities[player]! / popularities[myPlayerName]!);
        final theScore =
            numTokens *
            ((influences[player]![myPlayerName]! -
                    influences[myPlayerName]![player]!) /
                (popularities[myPlayerName]! *
                    gameParams.popularityFunctionParams.cSteal *
                    gameParams.popularityFunctionParams.alpha));
        var cantidad =
            (min(
                      -1.0 * (theScore - keepingStrengthW) * multiplicador,
                      vengeanceMax,
                    ) +
                    0.5)
                .toInt();

        if (cantidad <= 0) {
          continue;
        }

        var myWeight = popularities[myPlayerName]! * cantidad;
        var ratio = (myWeight + attackClaimsMagnitude[player]!) / myWeight;

        var gain =
            myWeight -
            (popularities[player]! * keepingStrength[player]! / ratio);

        while (((((gain * ratio) / numTokens) *
                    gameParams.popularityFunctionParams.alpha *
                    gameParams.popularityFunctionParams.cSteal) >
                (popularities[player]! -
                    gameParams.popularityFunctionParams.povertyLine)) &&
            (cantidad > 0)) {
          cantidad -= 1;
          if (cantidad == 0) break;

          myWeight = popularities[myPlayerName]! * cantidad;
          ratio = (myWeight + attackClaimsMagnitude[player]!) / myWeight;

          gain =
              myWeight -
              (popularities[player]! * keepingStrength[player]! / ratio);
        }

        final stealROI =
            (gain * gameParams.popularityFunctionParams.cSteal) /
            (cantidad * popularities[myPlayerName]!);
        final damage =
            (gain / numTokens) *
            gameParams.popularityFunctionParams.cSteal *
            gameParams.popularityFunctionParams.alpha;

        var immGainPerToken =
            (stealROI - ROI) *
            ((cantidad / numTokens) * popularities[myPlayerName]!) *
            gameParams.popularityFunctionParams.alpha;
        immGainPerToken /= cantidad;

        final vengeanceAdvantage = immGainPerToken + damage / cantidad;

        if (vengeanceAdvantage > 0) {
          vengeancePossibilities.add(Tuple2(player, vengeanceAdvantage));
        }
      }
    }

    return vengeancePossibilities;
  }

  void calculateIndividualFear() {
    for (final player in currentRound.info.playerPopularities.keys) {
      fear[player] = 0;
    }

    if (!useFear) {
      return;
    }

    // aggression `TODO` add something to weigh differently of attacks on anyone vs attacks on your friends
    final sumNegInfl = inflNeg.map(
      (key, value) => MapEntry(
        key,
        value.values.reduce((value, element) => value + element),
      ),
    );
    final sumPosInflWOSelf = inflPos.map(
      (key, value) => MapEntry(
        key,
        value.entries.fold<double>(0, (value, entry) {
          if (key == entry.key) {
            return value;
          } else {
            return value + entry.value;
          }
        }),
      ),
    );

    final totalInfluence = sumNegInfl.map(
      (key, value) => MapEntry(key, value + sumPosInflWOSelf[key]!),
    );
    final aggression = sumNegInfl.map(
      (key, value) => MapEntry(key, value / totalInfluence[key]!),
    );

    // size
    final sizeRelativeToMe = currentRound.info.playerPopularities.map(
      (key, value) => MapEntry(
        key,
        value / currentRound.info.playerPopularities[myPlayerName]!,
      ),
    );

    // measures how much bigger or smaller they are than me, anything more than double is considered the same
    sizeRelativeToMe.updateAll((key, value) {
      return (value - 1).clamp(0, 1);
    });

    // growth - ratio of growth of player to growth of me

    final roundNum = currentRound.info.round;
    num avgGrowth = 0;

    final growth = currentRound.info.playerPopularities.map((
      them,
      theirPopularity,
    ) {
      num theirGrowth;

      if (roundNum > initialRound + GROWTH_WINDOW - 1) {
        theirGrowth =
            (theirPopularity -
                currentRound.popularities[roundNum - GROWTH_WINDOW]![them]!) /
            GROWTH_WINDOW;

        if (theirGrowth < 0) {
          theirGrowth = 0;
        }
      } else {
        theirGrowth = 0;
      }

      return MapEntry(them, theirGrowth);
    });

    avgGrowth =
        growth.values.reduce((value, element) => value + element) /
        growth.length;

    // measures how much faster they are growing than me, anything more than double is considered the same
    final growthRelativeToAvg = growth.map((key, value) {
      if (avgGrowth == 0) {
        return MapEntry(key, 0);
      }
      value = value / avgGrowth;
      return MapEntry(key, (value - 1).clamp(0, 1));
    });

    // fear contagion
    final fearContagion = {
      for (final player in currentRound.info.groupMembers) player: 0.0,
    };
    for (final playerFear in othersFear.values) {
      for (final otherPlayer in playerFear.keys) {
        fearContagion[otherPlayer] =
            fearContagion[otherPlayer]! + playerFear[otherPlayer]!;
      }
    }

    fearContagion.updateAll(
      (key, value) => value / (currentRound.info.numPlayers - 1),
    );

    // fear calculation - should be between 0 and 1
    for (final player in currentRound.info.playerPopularities.keys) {
      fear[player] =
          ((activeGenes!.fearAggression / 100 * aggression[player]!) +
              (activeGenes!.fearSize / 100 * sizeRelativeToMe[player]!) +
              (activeGenes!.fearGrowth / 100 * growthRelativeToAvg[player]!) +
              (activeGenes!.fearContagion / 100 * fearContagion[player]!)) /
          4;
    }
  }

  void calculateGroupFear(Set<String> group) {
    if (!useFear) {
      return;
    }

    groupFear.addEntries([MapEntry(group, 0)]);

    // aggression `TODO` add something to weigh differently of attacks on anyone vs attacks on your friends
    final sumNegInfl = inflNeg.map(
      (key, value) => MapEntry(
        key,
        value.values.reduce((value, element) => value + element),
      ),
    );
    final sumPosInflWOSelf = inflPos.map(
      (key, value) => MapEntry(
        key,
        value.entries.fold<double>(0, (value, entry) {
          if (key == entry.key) {
            return value;
          } else {
            return value + entry.value;
          }
        }),
      ),
    );

    //$\mathcal{I}^+_{k,j}(\tau) = \max(0,\mathcal{I}_{k,j}(\tau))$
    //$\mathcal{I}^-_{k,j}(\tau) = |\min(0,\mathcal{I}_{k,j}(\tau))|$
    //aggression = $\mathcal{I}^-_i / mathcal{I}^-_i + mathcal{I}^+_i$

    final totalInfluence = sumNegInfl.map(
      (key, value) => MapEntry(key, value + sumPosInflWOSelf[key]!),
    );
    final aggression = sumNegInfl.map(
      (key, value) => MapEntry(key, value / totalInfluence[key]!),
    );

    var groupAggression = 0.0;
    for (final player in group) {
      groupAggression += aggression[player]!;
    }
    groupAggression /= group.length;

    // size
    // sizeRelativeToMe = $\mathcal{P}_j / \mathcal{P}_i$
    final myGroupSize =
        nextGroup?.fold<double>(0, (previousValue, element) {
          return currentRound.info.playerPopularities[element]! + previousValue;
        }) ??
        currentRound.info.playerPopularities[myPlayerName]!;

    final theirSize = group.fold<double>(0, (previousValue, element) {
      return currentRound.info.playerPopularities[element]! + previousValue;
    });

    var sizeRelativeToMe = theirSize / myGroupSize;

    // measures how much bigger or smaller they are than me, anything more than double is considered the same
    sizeRelativeToMe = (sizeRelativeToMe - 1).clamp(0, 1);

    // growth - ratio of growth of player to growth of me

    final roundNum = currentRound.info.round;
    num myGroupsGrowth;

    // growth = $\frac{\mathcal{P}_i(\tau) - \mathcal{P}_i(\tau - \Delta \tau)}{\Delta \tau}$

    if (roundNum > initialRound + GROWTH_WINDOW - 1) {
      final myGroupPreviousSize =
          nextGroup?.fold<double>(0, (previousValue, element) {
            return currentRound.popularities[roundNum -
                    GROWTH_WINDOW]![element]! +
                previousValue;
          }) ??
          currentRound.popularities[roundNum - GROWTH_WINDOW]![myPlayerName]!;

      myGroupsGrowth = (myGroupSize - myGroupPreviousSize) / GROWTH_WINDOW;

      if (myGroupsGrowth < .01) {
        myGroupsGrowth = .01;
      }
    } else {
      myGroupsGrowth = 1;
    }

    num theirGrowth;

    if (roundNum > initialRound + 3) {
      final theirPreviousSize = group.fold<double>(0, (previousValue, element) {
        return currentRound.popularities[roundNum - GROWTH_WINDOW]![element]! +
            previousValue;
      });

      theirGrowth = (theirSize - theirPreviousSize) / GROWTH_WINDOW;

      if (theirGrowth < 0) {
        theirGrowth = 0;
      }
    } else {
      theirGrowth = 0;
    }

    var growthRelativeToMe = theirGrowth / myGroupsGrowth;

    // measures how much faster they are growing than me, anything more than double is considered the same
    growthRelativeToMe = (growthRelativeToMe - 1).clamp(0, 1);

    // fear contagion
    final fearContagion = {
      for (final player in currentRound.info.playerPopularities.keys)
        player: 0.0,
    };
    for (final playerFear in othersFear.values) {
      for (final otherPlayer in playerFear.keys) {
        fearContagion[otherPlayer] =
            fearContagion[otherPlayer]! + playerFear[otherPlayer]!;
      }
    }

    fearContagion.updateAll(
      (key, value) => value / (currentRound.info.numPlayers - 1),
    );

    var groupFearContagion = 0.0;
    for (final player in group) {
      groupFearContagion += fearContagion[player]!;
    }

    groupFearContagion /= group.length;

    // fear calculation - should be between 0 and 1
    // groupFear = $\frac{\theta_{fearAgression}$ * aggression + $\theta_{fearSize}$ * sizeRelativeToMe + $\theta_{fearGrowth}$ * growthRelativeToMe + $\theta_{fearContagion}$ * groupFearContagion}{100*4}$
    groupFear[group] =
        ((activeGenes!.fearAggression / 100 * groupAggression) +
            (activeGenes!.fearSize / 100 * sizeRelativeToMe) +
            (activeGenes!.fearGrowth / 100 * growthRelativeToMe) +
            (activeGenes!.fearContagion / 100 * groupFearContagion)) /
        4;
  }

  @override
  Tuple2<String?, int> pillageTheVillage(
    Set<String> selectedCommunity,
    int remainingToks,
    Map<String, double> groupCat,
  ) {
    final popularities = currentRound.info.playerPopularities;
    final roundNum = currentRound.info.round;
    final numTokens = currentRound.info.playerTokens;
    final players = popularities.keys;
    final influences = transposeMap(
      removeIntrinsic(currentRound.info.playerInfluences),
    );

    if ((popularities[myPlayerName]! <= 0) ||
        ((roundNum - 1) < (activeGenes!.pillageDelay / 10)) ||
        (activeGenes!.pillagePriority < 50)) {
      return const Tuple2(null, 0);
    }

    final numAttackTokens = min(
      remainingToks,
      (numTokens * (activeGenes!.pillageFury / 100) + .5).toInt(),
    );
    if (numAttackTokens <= 0) {
      return const Tuple2(null, 0);
    }

    // Magnitude of the attacks stated by A on B weighted by the popularity of A and trust of A
    final attackClaimsMagnitudeMatrix = attackClaims.map(
      (A, value) => MapEntry(
        A,
        value.map((B, tokens) {
          if (tokens == 0 && potentialAttackClaims[A]![B] == 1 && A != B) {
            // If they want to attack assume they'll attack with the same amount as me
            return MapEntry(B, remainingToks * popularities[A]! * trustMap[A]!);
          }

          return MapEntry(B, tokens * popularities[A]! * trustMap[A]!);
        }),
      ),
    );

    // Sum of the magnitude of the attacks stated by everyone on each player
    final attackClaimsMagnitude = {for (final player in players) player: 0.0};
    for (final A in players) {
      for (final B in players) {
        attackClaimsMagnitude[B] =
            attackClaimsMagnitude[B]! + attackClaimsMagnitudeMatrix[A]![B]!;
      }
    }

    final pillagePossibilities = <List>[];
    for (final player in players) {
      if ((currentRound.info.governmentRoundInfo.governmentPlayerNames
                  ?.contains(player) ??
              false) ||
          player == myPlayerName) {
        continue;
      }

      if (groupCat[player]! < 2 &&
          ((!selectedCommunity.contains(player)) ||
              activeGenes!.pillageFriends >= 50)) {
        // playerName is not fearful of the group player is in and player_idx is willing to pillage friends (if i is a friend)
        var cantidad = numAttackTokens;
        var myWeight = popularities[myPlayerName]! * cantidad;
        var ratio = (myWeight + attackClaimsMagnitude[player]!) / myWeight;

        var gain =
            myWeight -
            (popularities[player]! * keepingStrength[player]! / ratio);

        while (((((gain * ratio) / numTokens) *
                    gameParams.popularityFunctionParams.alpha *
                    gameParams.popularityFunctionParams.cSteal) >
                popularities[player]! -
                    gameParams.popularityFunctionParams.povertyLine) &&
            (cantidad > 0)) {
          cantidad -= 1;

          if (cantidad == 0) break;

          myWeight = popularities[myPlayerName]! * cantidad;
          ratio = (myWeight + attackClaimsMagnitude[player]!) / myWeight;

          gain =
              myWeight -
              (popularities[player]! * keepingStrength[player]! / ratio);
        }

        if (cantidad == 0) continue;
        final stealROI =
            (gain * gameParams.popularityFunctionParams.cSteal) /
            (cantidad * popularities[myPlayerName]!);
        final damage =
            (gain / numTokens) *
            gameParams.popularityFunctionParams.cSteal *
            gameParams.popularityFunctionParams.alpha;

        var immGainPerToken =
            stealROI *
            ((cantidad / numTokens) * popularities[myPlayerName]!) *
            gameParams.popularityFunctionParams.alpha;
        final friendPenalty =
            (1.0 - gameParams.popularityFunctionParams.beta) *
            (damage / popularities[player]!) *
            influences[player]![myPlayerName]!;
        immGainPerToken -= friendPenalty;

        immGainPerToken -=
            ROI *
            ((cantidad / numTokens) * popularities[myPlayerName]!) *
            gameParams.popularityFunctionParams.alpha;

        immGainPerToken /= cantidad;

        //identify security threats
        final securityThreatAdvantage = immGainPerToken + damage / cantidad;
        final num myGrowth;
        final num theirGrowth;
        if (roundNum > initialRound + 3) {
          myGrowth =
              (currentRound.popularities[roundNum]![myPlayerName]! -
                  currentRound.popularities[roundNum - 4]![myPlayerName]!) /
              4.0;

          theirGrowth =
              (currentRound.popularities[roundNum]![player]! -
                  currentRound.popularities[roundNum - 4]![player]!) /
              4.0;
        } else {
          myGrowth = 0;
          theirGrowth = 0;
        }

        if ((theirGrowth > (1.5 * myGrowth)) &&
                (popularities[player]! > popularities[myPlayerName]!) &&
                (!selectedCommunity.contains(player)) ||
            groupCat[player] == 1) {
          immGainPerToken += securityThreatAdvantage;
        }

        final margin = activeGenes!.pillageMargin / 100;
        if (immGainPerToken > margin) {
          pillagePossibilities.add([player, immGainPerToken, cantidad]);
        }
      }
    }

    // random selection
    if (pillagePossibilities.isNotEmpty) {
      var mag = 0.0;
      for (final i in pillagePossibilities) {
        mag += i[1]! as double;
      }

      double num;
      if (USE_RANDOM) {
        num = Random().nextDouble();
      } else {
        num = .5;
      }

      var sumR = 0.0;

      for (final i in pillagePossibilities) {
        sumR += (i[1]! as double) / mag;
        if (num <= sumR) {
          return Tuple2(i[0] as String, i[2] as int);
        }
      }
    }

    return const Tuple2(null, 0);
  }

  @override
  Tuple2<Map<String, int>, int> quienAtaco(
    int remainingToks,
    Set<String> selectedCommunity,
    List<Set<String>> communities,
  ) {
    final players = currentRound.info.playerPopularities.keys;
    final groupCat = groupCompare(communities);

    // print('remaining tokens: $remainingToks');

    final pillageChoice = pillageTheVillage(
      selectedCommunity,
      remainingToks,
      groupCat,
    );
    // print('PILLAGERS : ${activeGenes!.pillagePriority}');
    // print(pillageChoice);

    final vengeanceChoice = takeVengeance(remainingToks);
    // print('VENGEANCE');
    // print(vengeanceChoice);
    final defendFriendChoice = defendFriend(
      remainingToks,
      selectedCommunity,
      communities,
      groupCat,
    );

    final fearChoice = fearAttack(remainingToks, selectedCommunity, groupCat);

    final attackToks = {for (final player in players) player: 0};

    final attackPossibilities = <Tuple2<int, Tuple2<String?, int>>>[];
    if (pillageChoice.first != null) {
      attackPossibilities.add(
        Tuple2(activeGenes!.pillagePriority, pillageChoice),
      );
    }
    if (vengeanceChoice.first != null) {
      attackPossibilities.add(
        Tuple2(activeGenes!.vengeancePriority, vengeanceChoice),
      );
    }
    if (defendFriendChoice.first != null) {
      attackPossibilities.add(
        Tuple2(activeGenes!.defendFriendPriority, defendFriendChoice),
      );
    }
    if (fearChoice.first != null) {
      attackPossibilities.add(Tuple2(activeGenes!.fearPriority, fearChoice));
    }

    // decide which attack to do
    if (attackPossibilities.isNotEmpty) {
      attackPossibilities.sortReversed((a, b) => a.first.compareTo(b.first));
      if ((attackPossibilities[0].second.first != defendFriendChoice[0]) ||
          (attackPossibilities[0].second.second != defendFriendChoice[1])) {
        expectedDefendFriendDamage = -99999;
      }
      attackToks[attackPossibilities[0].second.first!] =
          attackPossibilities[0].second.second;
    } else {
      expectedDefendFriendDamage = -99999;
    }

    return Tuple2(attackToks, attackToks.values.sum);
  }

  List<(String, double, int)> envisionFearAttack(
    int remainingToks,
    Set<String> selectedCommunity,
  ) {
    final fearedPlayers = getFearedPlayers(selectedCommunity);

    final popularities = currentRound.info.playerPopularities;
    final numTokens = currentRound.info.playerTokens;
    final players = popularities.keys;

    if (popularities[myPlayerName]! <= 0) {
      return [];
    }

    // Magnitude of the attacks stated by A on B weighted by the popularity of A and trust of A
    // Envision everyone in my group attacking each player
    final attackClaimsMagnitudeMatrix = attackClaims.map(
      (A, value) => MapEntry(
        A,
        value.map((B, tokens) {
          if (tokens == 0 && (nextGroup?.contains(A) ?? false) && A != B) {
            // assume they'll attack with the same amount as me
            return MapEntry(B, remainingToks * popularities[A]! * trustMap[A]!);
          }

          return MapEntry(B, tokens * popularities[A]! * trustMap[A]!);
        }),
      ),
    );

    // Sum of the magnitude of the attacks stated by everyone on each player
    final attackClaimsMagnitude = {for (final player in players) player: 0.0};
    for (final A in players) {
      for (final B in players) {
        attackClaimsMagnitude[B] =
            attackClaimsMagnitude[B]! + attackClaimsMagnitudeMatrix[A]![B]!;
      }
    }

    final fearAttackPossibilities = <(String, double, int)>[];
    for (final player in fearedPlayers) {
      if ((currentRound.info.governmentRoundInfo.governmentPlayerNames
                  ?.contains(player) ??
              false) ||
          player == myPlayerName) {
        continue;
      }
      var amountToSteal =
          numTokens *
          fear[player]! /
          (popularities[myPlayerName]! *
              gameParams.popularityFunctionParams.cSteal *
              gameParams.popularityFunctionParams.alpha);
      amountToSteal +=
          keepingStrength[player]! *
          (popularities[player]! / popularities[myPlayerName]!);
      var tokensToSteal = min(amountToSteal.round(), remainingToks);

      if (tokensToSteal <= 0) {
        continue;
      }

      var myWeight = popularities[myPlayerName]! * tokensToSteal;
      var ratio = (myWeight + attackClaimsMagnitude[player]!) / myWeight;

      var gain =
          myWeight - (popularities[player]! * keepingStrength[player]! / ratio);

      // Don't overkill the player
      while (((((gain * ratio) / numTokens) *
                  gameParams.popularityFunctionParams.alpha *
                  gameParams.popularityFunctionParams.cSteal) >
              (popularities[player]! -
                  gameParams.popularityFunctionParams.povertyLine)) &&
          (tokensToSteal > 0)) {
        tokensToSteal -= 1;
        if (tokensToSteal == 0) break;

        myWeight = popularities[myPlayerName]! * tokensToSteal;
        ratio = (myWeight + attackClaimsMagnitude[player]!) / myWeight;

        gain =
            myWeight -
            (popularities[player]! * keepingStrength[player]! / ratio);
      }

      final stealROI =
          (gain * gameParams.popularityFunctionParams.cSteal) /
          (tokensToSteal * popularities[myPlayerName]!);
      final damage =
          (gain / numTokens) *
          gameParams.popularityFunctionParams.cSteal *
          gameParams.popularityFunctionParams.alpha;

      var immGainPerToken =
          (stealROI - ROI) *
          ((tokensToSteal / numTokens) * popularities[myPlayerName]!) *
          gameParams.popularityFunctionParams.alpha;
      immGainPerToken /= tokensToSteal;

      final fearAttackAdvantage = immGainPerToken + damage / tokensToSteal;

      if (fearAttackAdvantage > 0) {
        fearAttackPossibilities.add((
          player,
          fearAttackAdvantage,
          tokensToSteal,
        ));
      }
    }

    // print('$myPlayerName: envisionFearAttack $fearAttackPossibilities');

    return fearAttackPossibilities;
  }

  Tuple2<String?, int> fearAttack(
    int remainingToks,
    Set<String> selectedCommunity,
    Map<String, double> groupCat,
  ) {
    final fearedPlayers = getFearedPlayers(selectedCommunity);

    final popularities = currentRound.info.playerPopularities;
    final numTokens = currentRound.info.playerTokens;
    final players = popularities.keys;

    if (popularities[myPlayerName]! <= 0) {
      return const Tuple2(null, 0);
    }

    // Magnitude of the attacks stated by A on B weighted by the popularity of A and trust of A
    final attackClaimsMagnitudeMatrix = attackClaims.map(
      (A, value) => MapEntry(
        A,
        value.map((B, tokens) {
          if (tokens == 0 && potentialAttackClaims[A]![B] == 1 && A != B) {
            // If they want to attack assume they'll attack with the same amount as me
            return MapEntry(B, remainingToks * popularities[A]! * trustMap[A]!);
          }

          return MapEntry(B, tokens * popularities[A]! * trustMap[A]!);
        }),
      ),
    );

    // Sum of the magnitude of the attacks stated by everyone on each player
    final attackClaimsMagnitude = {for (final player in players) player: 0.0};
    for (final A in players) {
      for (final B in players) {
        attackClaimsMagnitude[B] =
            attackClaimsMagnitude[B]! + attackClaimsMagnitudeMatrix[A]![B]!;
      }
    }

    final fearAttackPossibilities = <(String, double, int)>[];
    for (final player in fearedPlayers) {
      if ((currentRound.info.governmentRoundInfo.governmentPlayerNames
                  ?.contains(player) ??
              false) ||
          player == myPlayerName) {
        continue;
      }

      // TODO: find a better way to calculate the amount to steal
      var amountToSteal =
          numTokens *
          fear[player]! /
          (popularities[myPlayerName]! *
              gameParams.popularityFunctionParams.cSteal *
              gameParams.popularityFunctionParams.alpha);
      amountToSteal +=
          keepingStrength[player]! *
          (popularities[player]! / popularities[myPlayerName]!);
      var tokensToSteal = min(amountToSteal.round(), remainingToks);

      if (tokensToSteal <= 0) {
        continue;
      }

      var myWeight = popularities[myPlayerName]! * tokensToSteal;
      var ratio = (myWeight + attackClaimsMagnitude[player]!) / myWeight;

      var gain =
          myWeight - (popularities[player]! * keepingStrength[player]! / ratio);

      // Don't overkill the player
      while (((((gain * ratio) / numTokens) *
                  gameParams.popularityFunctionParams.alpha *
                  gameParams.popularityFunctionParams.cSteal) >
              (popularities[player]! -
                  gameParams.popularityFunctionParams.povertyLine)) &&
          (tokensToSteal > 0)) {
        tokensToSteal -= 1;
        if (tokensToSteal == 0) break;

        myWeight = popularities[myPlayerName]! * tokensToSteal;
        ratio = (myWeight + attackClaimsMagnitude[player]!) / myWeight;

        gain =
            myWeight -
            (popularities[player]! * keepingStrength[player]! / ratio);
      }

      final stealROI =
          (gain * gameParams.popularityFunctionParams.cSteal) /
          (tokensToSteal * popularities[myPlayerName]!);
      final damage =
          (gain / numTokens) *
          gameParams.popularityFunctionParams.cSteal *
          gameParams.popularityFunctionParams.alpha;

      var immGainPerToken =
          (stealROI - ROI) *
          ((tokensToSteal / numTokens) * popularities[myPlayerName]!) *
          gameParams.popularityFunctionParams.alpha;
      immGainPerToken /= tokensToSteal;

      final fearAttackAdvantage = immGainPerToken + damage / tokensToSteal;

      if (fearAttackAdvantage > 0) {
        fearAttackPossibilities.add((
          player,
          fearAttackAdvantage,
          tokensToSteal,
        ));
      }
    }

    // print('$myPlayerName: fearAttack $fearAttackPossibilities');

    // random selection
    if (fearAttackPossibilities.isNotEmpty) {
      var mag = 0.0;
      for (final i in fearAttackPossibilities) {
        mag += i.$2;
      }

      double num;
      if (USE_RANDOM) {
        num = Random().nextDouble();
      } else {
        num = .5;
      }

      var sumr = 0.0;

      for (final i in fearAttackPossibilities) {
        sumr += (i.$2) / mag;
        if (num <= sumr) {
          return Tuple2(i.$1, i.$3);
        }
      }
    }

    return const Tuple2(null, 0);
  }
}

class CommunityEvaluationWithChat extends CommunityEvaluation {
  CommunityEvaluationWithChat({
    required super.s,
    required super.modularity,
    required super.centrality,
    required super.collectiveStrength,
    required super.familiarity,
    required super.prosocial,
    required this.chatAgreement,
    required this.trust,
    required this.isCurrentCommunity,
  });

  final double chatAgreement;
  final double trust;
  final bool isCurrentCommunity;

  ///Community evaluation scores are multiplied by this if they are not the current group.
  ///This is to discourage sporadic changing
  static const CHANGE_COST = 1; //.80;

  @override
  double computeScore(Genes genes) {
    score = 1.0;
    score = getModularityVal(genes);
    score *= getCentralityVal(genes);
    score *= getCollectiveStrengthVal(genes);
    score *= getFamiliarityVal(genes);
    score *= getProsocialVal(genes);
    score *= getChatAgreementVal(genes);
    score *= getTrustVal(genes);
    if (!isCurrentCommunity) {
      score *= CHANGE_COST;
    }

    // if (USE_RANDOM) {
    //   score += Random().nextDouble() / 10.0;
    // } else {
    //   score += modularity / 10.0;
    // }
    return score;
  }

  double getChatAgreementVal(Genes genes) {
    return ((100 - genes.wChatAgreement) +
            (genes.wChatAgreement * chatAgreement)) /
        100.0;
  }

  double getTrustVal(Genes genes) {
    return ((100 - genes.wTrust) + (genes.wTrust * trust)) / 100.0;
  }

  double getChatAgreementDifference(
    CommunityEvaluationWithChat? otherCommunity,
    Genes genes,
  ) {
    return getChatAgreementVal(genes) -
        (otherCommunity?.getChatAgreementVal(genes) ?? 0);
  }

  double getTrustDifference(
    CommunityEvaluationWithChat? otherCommunity,
    Genes genes,
  ) {
    return getTrustVal(genes) - (otherCommunity?.getTrustVal(genes) ?? 0);
  }
}

extension StringExtensions on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
