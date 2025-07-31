import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';
// ignore: implementation_imports

import 'common.dart';

final agentProviders = <ProviderOrFamily>[
  botTypeProvider,
  chatMessageProvider,
  conversationsProvider,
  conversationIdProvider,
  conversationNameProvider,
  conversationParticipantsProvider,
  createConversationProvider,
  chatServiceProvider,
  createGameProvider,
  errorProvider,
  experienceProvider,
  gameCodeProvider,
  gameParamProvider,
  gameServiceProvider,
  isObserverProvider,
  joinGameProvider,
  lobbyProvider,
  multiplayerIdProvider,
  playerRealNameProvider,
  roundProvider,
  roundInfoBoxProvider,
  sendChatProvider,
  startGameProvider,
  tokenSubmissionProvider,
  playerIdProvider,
  gameIdProvider,
  realPlayerIdProvider,
  isCreatorProvider,
];

abstract class Agent {
  Agent(this.ref);

  Logger get logger => Logger('$agentType Agent $agentName');

  final AutoDisposeProviderRef ref;
  String get agentType;
  late Lobby lobby;
  late RoundState currentRound;
  late GameParams gameParams;
  late String gameCode;
  String get myPlayerName => _playerGameName ?? '';

  String get agentName =>
      _overriddenName ?? (_playerGameName != null ? '$agentType $_playerGameName' : agentType);
  set agentName(String name) => _overriddenName = name;

  String? _overriddenName;
  List<Conversation>? conversations;
  late int multiplayerId;
  String? _playerGameName;
  final finished = Completer<void>();

  /// Joins the game with code
  Future<void> join(GameCode code, {String? name}) async {
    logger.info('Joining game');
    ref.read(gameCodeProvider.notifier).state = code;
    ref.read(playerRealNameProvider.notifier).state = name ?? agentName;
    ref.read(isObserverProvider.notifier).state = false;
    ref.read(experienceProvider.notifier).state = PlayerExperience.advanced;
    ref.read(botTypeProvider.notifier).state = agentType;
    final success = await ref.read(joinGameProvider.future);
    _logErrors();
    assert(success, 'Agent failed to join game');
  }

  /// Creates a game and returns the game code
  Future<String> create(GameParams params) async {
    logger.info('Creating game');
    ref.read(playerRealNameProvider.notifier).state = agentName;
    ref.read(isObserverProvider.notifier).state = false;
    ref.read(gameParamProvider.notifier).params = params;
    ref.read(experienceProvider.notifier).state = PlayerExperience.advanced;
    ref.read(botTypeProvider.notifier).state = agentType;
    final success = await ref.read(createGameProvider.future);
    _logErrors();
    assert(success, 'Agent failed to create game');
    return ref.read(gameCodeProvider);
  }

  /// Joins the game with [code] and plays the game
  Future<void> joinAndPlay(GameCode code, {String? name}) async {
    await join(code, name: name);
    unawaited(play());
  }

  Future<void> start() async {
    logger.info('Starting game');
    await ref.read(startGameProvider.future);
  }

  /// Creates a game and returns the code for the game, additionally starts the
  /// agent playing the game
  Future<String> createAndPlay(GameParams gameParams) async {
    final code = await create(gameParams);
    unawaited(play());
    return code;
  }

  Future<void> leaveGame() async {
    logger.info('Leaving game');
    if (lobby.gameStarted) {
      finished.complete();
    } else {
      await ref.read(gameServiceProvider).leaveGame(LeaveGameRequest(
          gameId: ref.watch(gameIdProvider), playerId: ref.watch(playerIdProvider)));
    }

    // ref.read(gameIdProvider.notifier).state = '';
    // ref.read(realPlayerIdProvider.notifier).state = '';
    // ref.read(isObserverProvider.notifier).state = null;
    // ref.read(isCreatorProvider.notifier).state = null;
  }

  /// Plays the game that the agent has joined
  Future<void> play() async {
    multiplayerId = ref.read(multiplayerIdProvider);

    var started = false;
    logger.info('Playing game');
    final subs = <ProviderSubscription>[];
    final sub = ref.listen<AsyncValue<LobbyResponse>>(lobbyProvider, (prev, l) {
      final lobbyResponse = l.asData?.value;
      logger.fine('Got lobby');
      if (lobbyResponse != null) {
        lobby = lobbyResponse.lobby;
        if (lobbyResponse.params != null) {
          gameParams = lobbyResponse.params!;
          gameCode = lobbyResponse.lobby.code;
        }

        if (lobby.gameStarted && !started) {
          started = true;
          var first = true;
          subs.add(ref.listen(roundInfoBoxProvider, (_, __) {}));
          subs.add(ref.listen<AsyncValue<RoundState>>(roundProvider, (prev, round) {
            logger.fine('Got round info');
            if (round.asData != null) {
              final newRound = round.asData!.value;
              _playerGameName = newRound.info.playerName;
              if (first || newRound.info.round != currentRound.info.round) {
                currentRound = newRound;
                if (first) {
                  onGameStarted();
                }
                first = false;
                if (newRound.info.status.isGameOver) {
                  logger.info('Finished game round ${newRound.info.round} ${newRound.info.status}');
                  gameOver();
                  finished.complete();
                } else {
                  logger.info('Next round ${newRound.info.round}');
                  Future.delayed(const Duration(milliseconds: 10), nextRound);
                }
              }
            }
          }, fireImmediately: true));
          subs.add(ref.listen<AsyncValue<List<Conversation>>>(conversationsProvider, (prev, c) {
            if (c.asData != null) {
              conversations = c.asData!.value;
              newMessage();
            }
          }, fireImmediately: true));
        }
      }
    }, fireImmediately: true);

    await finished.future;
    for (final sub in subs) {
      sub.close();
    }
    sub.close();
  }

  /// Submits the [transactions]
  Future<bool> submitTransactions(PlayerRoundTransactions transactions) async {
    if (currentRound.info.round < 1) {
      logger.fine('Cannot submit transactions during preGame');
      return false;
    }
    if (currentRound.info.status != GameStatus.started) {
      logger.fine('Cannot submit transactions when game is not started or is over');
      return false;
    }
    if (finished.isCompleted) {
      logger.fine('Cannot submit transactions, left the game');
      return false;
    }
    logger.fine('Submitting transactions');
    _logErrors();
    ref.read(tokenSubmissionProvider.notifier).state = transactions;
    final result = await ref.read(roundProvider.notifier).submitTokens();
    _logErrors();
    assert(result, 'Agent submission failed');
    lastInfo = currentRound;
    return result;
  }

  void _logErrors() {
    final error = ref.read(errorProvider);
    if (error != '') {
      print(error);
      logger.severe('Agent error: $error');
    }
  }

  Future<bool> sendMessage(String message, String conversationId) async {
    ref.read(chatMessageProvider.notifier).update(
          (m) => m.copyWith(body: message),
        );
    ref.read(conversationIdProvider.notifier).state = conversationId;
    ref.read(chatMessageProvider.notifier).update((m) => m.copyWith(time: DateTime.now().toUtc()));

    final result = await ref.refresh(sendChatProvider.future);
    if (result) {
      ref.read(chatMessageProvider.notifier).update((m) => m.copyWith(body: ''));
    }
    return result;
  }

  Future<bool> createConversation(String name, List<String> members) async {
    if (conversations?.any((c) => c.name == name) ?? false) {
      return false;
    }
    // ref.read(conversationNameProvider.notifier).state = name;
    // members.add(myPlayerName);
    // ref.read(conversationParticipantsProvider.notifier).state = members.toSet();

    // return await ref.refresh(createConversationProvider.future);

    if (name == '' || name == 'Global Chat') {
      return false;
    }
    if (members.isEmpty) {
      return false;
    }
    final value = await ref.read(chatServiceProvider).createConversation(
        CreateConversationRequest(
          playerId: ref.read(playerIdProvider),
          gameId: ref.read(gameIdProvider),
          name: name,
          participants: members.toSet(),
        ),
        null);

    if (value.conversationId != '') {
      return true;
    }

    return false;
  }

  /// Called when the agent needs to handle a new round
  Future<void> nextRound();

  /// Called when the agent needs to handle new messages
  Future<void> newMessage();

  //Called when the game has started
  Future<void> onGameStarted() async {}

  /// Called when the game ends
  Future<void> gameOver() async {}

  RoundState? lastInfo;
}
