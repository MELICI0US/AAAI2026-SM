import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dart_random_choice/dart_random_choice.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:ml_linalg/linalg.dart';
import 'package:riverpod/riverpod.dart';

import '../../../jhg_core.dart';
import '../common.dart';
import 'no_chat_genes.dart';

final geneAgentProvider = Provider.autoDispose(GeneAgent.new, dependencies: [...agentProviders]);

const USE_RANDOM = true;
const NUMBER_OF_GENES = 45;

class Genes {
  Genes({
    required this.visualTrait,
    required this.alpha,
    required this.homophily,
    required this.otherishDebtLimits,
    required this.coalitionTarget,
    // proportion of tokens to give out evenly in group_allocate
    required this.fixedUsage,
    required this.wModularity,
    required this.wCentrality,
    required this.wCollectiveStrength,
    required this.wFamiliarity,
    required this.wProsocial,
    required this.initialDefense,
    required this.minKeep,
    required this.defenseUpdate,
    required this.defensePropensity,
    required this.fearDefense,
    required this.safetyFirst,
    required this.pillageFury,
    required this.pillageDelay,
    required this.pillagePriority,
    required this.pillageMargin,
    required this.pillageCompanionship,
    required this.pillageFriends,
    required this.vengeanceMultiplier,
    required this.vengeanceMax,
    required this.vengeancePriority,
    required this.defendFriendMultiplier,
    required this.defendFriendMax,
    required this.defendFriendPriority,
    required this.attackGoodGuys,
    required this.limitingGive,
    required this.groupAware,
    required this.joinCoop,
    // new genes added for chatterbots
    required this.trustRate,
    required this.distrustRate,
    required this.startingTrust,
    required this.wChatAgreement,
    required this.wTrust,
    required this.wAccusations,
    required this.fearAggression,
    required this.fearGrowth,
    required this.fearSize,
    required this.fearContagion,
    required this.fearThreshold,
    required this.fearPriority,
  });

  factory Genes.fromGeneString(String geneString, int geneSetIndex) {
    final geneList = geneString.split('_');

    //+1 skips 'gene' at the beginning
    final offset = NUMBER_OF_GENES * geneSetIndex + 1;
    if (offset + NUMBER_OF_GENES > geneList.length) {
      throw Exception('Gene string does not have enough items');
    }

    return Genes(
      visualTrait: int.parse(geneList[0 + offset]),
      homophily: int.parse(geneList[1 + offset]),
      alpha: int.parse(geneList[2 + offset]),
      otherishDebtLimits: int.parse(geneList[3 + offset]),
      coalitionTarget: int.parse(geneList[4 + offset]),
      fixedUsage: int.parse(geneList[5 + offset]),
      wModularity: int.parse(geneList[6 + offset]),
      wCentrality: int.parse(geneList[7 + offset]),
      wCollectiveStrength: int.parse(geneList[8 + offset]),
      wFamiliarity: int.parse(geneList[9 + offset]),
      wProsocial: int.parse(geneList[10 + offset]),
      initialDefense: int.parse(geneList[11 + offset]),
      minKeep: int.parse(geneList[12 + offset]),
      defenseUpdate: int.parse(geneList[13 + offset]),
      defensePropensity: int.parse(geneList[14 + offset]),
      fearDefense: int.parse(geneList[15 + offset]),
      safetyFirst: int.parse(geneList[16 + offset]),
      pillageFury: int.parse(geneList[17 + offset]),
      pillageDelay: int.parse(geneList[18 + offset]),
      pillagePriority: int.parse(geneList[19 + offset]),
      pillageMargin: int.parse(geneList[20 + offset]),
      pillageCompanionship: int.parse(geneList[21 + offset]),
      pillageFriends: int.parse(geneList[22 + offset]),
      vengeanceMultiplier: int.parse(geneList[23 + offset]),
      vengeanceMax: int.parse(geneList[24 + offset]),
      vengeancePriority: int.parse(geneList[25 + offset]),
      defendFriendMultiplier: int.parse(geneList[26 + offset]),
      defendFriendMax: int.parse(geneList[27 + offset]),
      defendFriendPriority: int.parse(geneList[28 + offset]),
      attackGoodGuys: int.parse(geneList[29 + offset]),
      limitingGive: int.parse(geneList[30 + offset]),
      groupAware: int.parse(geneList[31 + offset]),
      joinCoop: int.parse(geneList[32 + offset]),
      trustRate: int.parse(geneList[33 + offset]),
      distrustRate: int.parse(geneList[34 + offset]),
      startingTrust: int.parse(geneList[35 + offset]),
      wChatAgreement: int.parse(geneList[36 + offset]),
      wTrust: int.parse(geneList[37 + offset]),
      wAccusations: int.parse(geneList[38 + offset]),
      fearAggression: int.parse(geneList[39 + offset]),
      fearGrowth: int.parse(geneList[40 + offset]),
      fearSize: int.parse(geneList[41 + offset]),
      fearContagion: int.parse(geneList[42 + offset]),
      fearThreshold: int.parse(geneList[43 + offset]),
      fearPriority: int.parse(geneList[44 + offset]),
    );
  }

  final int visualTrait;
  final int alpha;
  final int homophily;
  final int otherishDebtLimits;
  final int coalitionTarget;
  // proportion of tokens to give out evenly in group_allocate
  final int fixedUsage;
  final int wModularity;
  final int wCentrality;
  final int wCollectiveStrength;
  final int wFamiliarity;
  final int wProsocial;
  final int initialDefense;
  final int minKeep;
  final int defenseUpdate;
  final int defensePropensity;
  final int fearDefense;
  final int safetyFirst;
  final int pillageFury;
  final int pillageDelay;
  final int pillagePriority;
  final int pillageMargin;
  final int pillageCompanionship;
  final int pillageFriends;
  final int vengeanceMultiplier;
  final int vengeanceMax;
  final int vengeancePriority;
  final int defendFriendMultiplier;
  final int defendFriendMax;
  final int defendFriendPriority;
  final int attackGoodGuys;
  final int limitingGive;
  final int groupAware;
  final int joinCoop;
  // New genes
  final int trustRate;
  final int distrustRate;
  final int startingTrust;
  final int wChatAgreement;
  final int wTrust;
  final int wAccusations;
  // Fear genes
  final int fearAggression;
  final int fearGrowth;
  final int fearSize;
  final int fearContagion;
  final int fearThreshold;
  final int fearPriority;

  //respondPropensity
  //chatDelay
  //liePropensity
  //discloseActions
  //obeyOthers
  //commandOthers

  void printGenes() {
    //print all of the genes in one string
    print(
        'visualTrait:$visualTrait alpha:$alpha homophily:$homophily otherishDebtLimits:$otherishDebtLimits coalitionTarget:$coalitionTarget fixedUsage:$fixedUsage wModularity:$wModularity wCentrality:$wCentrality wCollectiveStrength:$wCollectiveStrength wFamiliarity:$wFamiliarity wProsocial:$wProsocial initialDefense:$initialDefense minKeep:$minKeep defenseUpdate:$defenseUpdate defensePropensity:$defensePropensity fearDefense:$fearDefense safetyFirst:$safetyFirst pillageFury:$pillageFury pillageDelay:$pillageDelay pillagePriority:$pillagePriority pillageMargin:$pillageMargin pillageCompanionship:$pillageCompanionship pillageFriends:$pillageFriends vengeanceMultiplier:$vengeanceMultiplier vengeanceMax:$vengeanceMax vengeancePriority:$vengeancePriority defendFriendMultiplier:$defendFriendMultiplier defendFriendMax:$defendFriendMax defendFriendPriority:$defendFriendPriority attackGoodGuys:$attackGoodGuys limitingGive:$limitingGive groupAware:$groupAware joinCoop:$joinCoop trustRate:$trustRate distrustRate:$distrustRate startingTrust:$startingTrust wChatAgreement:$wChatAgreement wTrust:$wTrust wAccusations:$wAccusations fearAggression:$fearAggression fearGrowth:$fearGrowth fearSize:$fearSize fearContagion:$fearContagion fearThreshold:$fearThreshold fearPriority:$fearPriority');
  }

  void printGeneString() {
    print(
        'gene_${visualTrait}_${homophily}_${alpha}_${otherishDebtLimits}_${coalitionTarget}_${fixedUsage}_${wModularity}_${wCentrality}_${wCollectiveStrength}_${wFamiliarity}_${wProsocial}_${initialDefense}_${minKeep}_${defenseUpdate}_${defensePropensity}_${fearDefense}_${safetyFirst}_${pillageFury}_${pillageDelay}_${pillagePriority}_${pillageMargin}_${pillageCompanionship}_${pillageFriends}_${vengeanceMultiplier}_${vengeanceMax}_${vengeancePriority}_${defendFriendMultiplier}_${defendFriendMax}_${defendFriendPriority}_${attackGoodGuys}_${limitingGive}_${groupAware}_${joinCoop}_${trustRate}_${distrustRate}_${startingTrust}_${wChatAgreement}_${wTrust}_${wAccusations}_${fearAggression}_${fearGrowth}_${fearSize}_${fearContagion}_${fearThreshold}_$fearPriority');
  }

  String getGeneString(int numGeneCopies, {List<Genes>? otherGenes}) {
    final buffer = StringBuffer();
    buffer.write('gene');
    if (otherGenes?.isNotEmpty ?? false) {
      buffer.write(
          '_${visualTrait}_${homophily}_${alpha}_${otherishDebtLimits}_${coalitionTarget}_${fixedUsage}_${wModularity}_${wCentrality}_${wCollectiveStrength}_${wFamiliarity}_${wProsocial}_${initialDefense}_${minKeep}_${defenseUpdate}_${defensePropensity}_${fearDefense}_${safetyFirst}_${pillageFury}_${pillageDelay}_${pillagePriority}_${pillageMargin}_${pillageCompanionship}_${pillageFriends}_${vengeanceMultiplier}_${vengeanceMax}_${vengeancePriority}_${defendFriendMultiplier}_${defendFriendMax}_${defendFriendPriority}_${attackGoodGuys}_${limitingGive}_${groupAware}_${joinCoop}_${trustRate}_${distrustRate}_${startingTrust}_${wChatAgreement}_${wTrust}_${wAccusations}_${fearAggression}_${fearGrowth}_${fearSize}_${fearContagion}_${fearThreshold}_$fearPriority');
      for (final otherGene in otherGenes!) {
        buffer.write(
            '_${otherGene.visualTrait}_${otherGene.homophily}_${otherGene.alpha}_${otherGene.otherishDebtLimits}_${otherGene.coalitionTarget}_${otherGene.fixedUsage}_${otherGene.wModularity}_${otherGene.wCentrality}_${otherGene.wCollectiveStrength}_${otherGene.wFamiliarity}_${otherGene.wProsocial}_${otherGene.initialDefense}_${otherGene.minKeep}_${otherGene.defenseUpdate}_${otherGene.defensePropensity}_${otherGene.fearDefense}_${otherGene.safetyFirst}_${otherGene.pillageFury}_${otherGene.pillageDelay}_${otherGene.pillagePriority}_${otherGene.pillageMargin}_${otherGene.pillageCompanionship}_${otherGene.pillageFriends}_${otherGene.vengeanceMultiplier}_${otherGene.vengeanceMax}_${otherGene.vengeancePriority}_${otherGene.defendFriendMultiplier}_${otherGene.defendFriendMax}_${otherGene.defendFriendPriority}_${otherGene.attackGoodGuys}_${otherGene.limitingGive}_${otherGene.groupAware}_${otherGene.joinCoop}_${otherGene.trustRate}_${otherGene.distrustRate}_${otherGene.startingTrust}_${otherGene.wChatAgreement}_${otherGene.wTrust}_${otherGene.wAccusations}_${otherGene.fearAggression}_${otherGene.fearGrowth}_${otherGene.fearSize}_${otherGene.fearContagion}_${otherGene.fearThreshold}_${otherGene.fearPriority}');
      }
    }

    for (var copy = 0; copy < numGeneCopies; copy++) {
      buffer.write(
          '_${visualTrait}_${homophily}_${alpha}_${otherishDebtLimits}_${coalitionTarget}_${fixedUsage}_${wModularity}_${wCentrality}_${wCollectiveStrength}_${wFamiliarity}_${wProsocial}_${initialDefense}_${minKeep}_${defenseUpdate}_${defensePropensity}_${fearDefense}_${safetyFirst}_${pillageFury}_${pillageDelay}_${pillagePriority}_${pillageMargin}_${pillageCompanionship}_${pillageFriends}_${vengeanceMultiplier}_${vengeanceMax}_${vengeancePriority}_${defendFriendMultiplier}_${defendFriendMax}_${defendFriendPriority}_${attackGoodGuys}_${limitingGive}_${groupAware}_${joinCoop}_${trustRate}_${distrustRate}_${startingTrust}_${wChatAgreement}_${wTrust}_${wAccusations}_${fearAggression}_${fearGrowth}_${fearSize}_${fearContagion}_${fearThreshold}_$fearPriority');
    }

    return buffer.toString();
  }
}

class GeneAgent extends Agent {
  GeneAgent(super.ref, {this.numGeneCopies = 3, this.genes});

  ///Just used to initialize genes. Should not be used for anything else
  final String? genes;
  List<Genes> genePools = [];
  Genes? activeGenes;
  final initialRound = 1;
  late double alpha;
  late Map<String, double> tally;
  late Map<String, double> unpaidDebt;
  late Map<String, double> punishableDebt;
  late Map<String, double> expectedReturn;
  late double aveReturn;
  late Map<String, double> scaledBackNums;
  late double receivedValue;
  late double investedValue;
  late double ROI;
  Map<String, double>? prevPopularities;
  Map<String, double>? prevAllocations;
  Map<String, Map<String, double>>? prevInfluence;
  late double coalitionTarget;
  late Map<String, double> keepingStrength;
  late double underAttack;
  late Map<String, double> visualTraits;
  final int numGeneCopies;

  late Map<String, Map<String, double>> inflNeg;
  late Map<String, Map<String, double>> inflPos;
  late Map<String, Map<String, double>> inflNegPrev;
  late Map<String, double> inflPosSumCol;
  late Map<String, double> inflPosSumRow;
  late Map<String, Map<String, double>> sumInflPos;
  late Map<String, double> attacksWithMe;
  late Map<String, double> othersAttackOn;
  late Map<String, double> badGuys;
  late double inflictedDamageRatio;
  double expectedDefendFriendDamage = 99999;
  late Map<String, double> meImporta;
  List<Set<String>> observedCommunities = [];

  int TEMP_TRUST_RATE = 10;
  int TEMP_DISTRUST_RATE = 30;
  int TEMP_STARTING_TRUST = 100;
  int TEMP_W_CHAT_AGREEMENT = 75;
  int TEMP_W_TRUST = 75;
  int TEMP_W_ACCUSATIONS = 100;

  @override
  String get agentType => 'Gene $genes';

  @override
  Future<void> newMessage() async {}

  @override
  Future<void> nextRound() async {
    // print(
    //     'agent.play_round(0, ${currentRound.info.round}, np.array([${currentRound.info.tokensReceived?.values}]), np.array([${currentRound.info.playerPopularities.values}]), np.array([${mapToMatrix(transposeMap(removeIntrinsic(currentRound.info.playerInfluences)))}]), {})');

    final roundNum = currentRound.info.round;
    final numPlayers = currentRound.info.groupMembers.length;
    final numTokens = currentRound.info.playerTokens;
    visualTraits = {for (final player in currentRound.info.playerPopularities.keys) player: 0};

    if (activeGenes == null) initializeGenes();

    if (roundNum == initialRound) {
      initVars();
    } else {
      updateVars();
    }

    alpha = activeGenes!.alpha / 100;

    computeUsefulQuantities();

    // group analysis and choice
    final groupAnalysisRes = groupAnalysis();
    final communities = groupAnalysisRes.first;
    final selectedCommunity = groupAnalysisRes.second;
    // print('community');
    // selectedCommunity.printCom();

    // figure out how many tokens to keep
    estimateKeeping(numPlayers, communities);

    final bool safetyFirst;
    if (activeGenes!.safetyFirst < 50) {
      safetyFirst = false;
    } else {
      safetyFirst = true;
    }

    var guardoToks = cuantoGuardo(selectedCommunity.s);
    // print('guardo');
    // print(guardoToks);

    // determine who to attack (if any)
    final Map<String, int> attackAlloc;
    final int numAttackToks;
    var remainingToks = 0;
    if (roundNum > initialRound) {
      remainingToks = currentRound.info.playerTokens;
      if (safetyFirst) {
        remainingToks -= guardoToks;
      }

      final atacoResult = quienAtaco(remainingToks, selectedCommunity.s, communities);
      // print('atacoResult');
      // print(atacoResult);
      attackAlloc = atacoResult.first;
      numAttackToks = atacoResult.second;
    } else {
      attackAlloc = {for (final player in currentRound.info.playerPopularities.keys) player: 0};
      remainingToks = numTokens - guardoToks;
      numAttackToks = 0;
    }

    // if (!safetyFirst) {
    //   guardoToks = min(guardoToks, numTokens - numAttackToks);
    // }

    // figure out who to give tokens to

    final groupsAlloc =
        groupGivings(numTokens - numAttackToks - guardoToks, selectedCommunity, attackAlloc).first;
    // print('groupsAlloc');
    // print(groupsAlloc);
    // print('attackAlloc');
    // print(attackAlloc);

    // update some variables
    final transactionVec = subtractIntVectors(groupsAlloc, attackAlloc);
    guardoToks =
        numTokens - transactionVec.map((key, value) => MapEntry(key, value.abs())).values.sum;

    transactionVec[myPlayerName] = transactionVec[myPlayerName]! + guardoToks;

    prevPopularities = currentRound.info.playerPopularities;
    prevAllocations = transactionVec.map((key, value) => MapEntry(key, value.toDouble()));
    prevInfluence = transposeMap(removeIntrinsic(currentRound.info.playerInfluences));

    updateIndebtedness(transactionVec);
    // print('updated indebtedness');

    if (transactionVec[myPlayerName]! < 0) {
      // ignore: avoid_print
      print('$myPlayerName is stealing from self!!!');
    }

    // print(
    //     '$myPlayerName transactions: ${transactionVec.map((key, value) => MapEntry(key, value.toDouble()))}');

    await submitTransactions(transactionVec.map((key, value) => MapEntry(key, value.toDouble())));
  }

  // HELPER FUNCTIONS FOR PYTHON TRANSLATION

  Map<String, double> clipVector(Map<String, double> map) {
    return map.map((key, value) => MapEntry(key, max(0, value)));
  }

  Map<String, Map<String, double>> clipMatrix(Map<String, Map<String, double>> map) {
    return map.map((key, value) => MapEntry(key, clipVector(value)));
  }

  Map<String, double> clipNegVector(Map<String, double> map) {
    return map.map((key, value) => MapEntry(key, value < 0 ? value.abs() : 0));
  }

  Map<String, Map<String, double>> clipNegMatrix(Map<String, Map<String, double>> map) {
    return map.map((key, value) =>
        MapEntry(key, value.map((key, value) => MapEntry(key, value < 0 ? value.abs() : 0))));
  }

  Map<String, double> sumOverAxis0(Map<String, Map<String, double>> map) {
    final newMap = {
      for (final player in map.keys) player: 0.0,
    };

    map.forEach((key1, value) {
      value.forEach((key2, infl) {
        newMap.update(key2, (value) => value + infl);
      });
    });

    return newMap;
  }

  Map<String, double> sumOverAxis1(Map<String, Map<String, double>> map) {
    return map.map((key, value) => MapEntry(key, value.values.sum));
  }

  Map<String, Map<String, double>> removeIntrinsic(Map<String, Map<String, double>> map) {
    final result = map.map((key, value) => MapEntry(key, Map<String, double>.from(value)));
    result.updateAll((key, value) => value..remove('__intrinsic__'));
    return result;
  }

  Map<String, Map<String, double>> transposeMap(Map<String, Map<String, double>> map) {
    final result = map.map((key, value) => MapEntry(key, Map<String, double>.from(value)));
    map.forEach((i, row) {
      row.forEach((j, value) {
        result[j]![i] = value;
      });
    });

    return result;
  }

  Map<String, Map<String, double>> addMatrices(
      Map<String, Map<String, double>> a, Map<String, Map<String, double>> b) {
    final result = a.map((rowKey, value) => MapEntry(
        rowKey, value.map((colKey, value) => MapEntry(colKey, value + b[rowKey]![colKey]!))));
    return result;
  }

  Map<String, int> addIntVectors(Map<String, int> a, Map<String, int> b) {
    return a.map((key, value) => MapEntry(key, value + b[key]!));
  }

  Map<String, int> subtractIntVectors(Map<String, int> a, Map<String, int> b) {
    return a.map((key, value) => MapEntry(key, value - b[key]!));
  }

  Map<String, double> subtractVectors(Map<String, double> a, Map<String, double> b) {
    return a.map((key, value) => MapEntry(key, value - b[key]!));
  }

  double dotVectors(Map<String, double> a, Map<String, double> b) {
    final newMap = a.map((key, value) => MapEntry(key, value * b[key]!));
    return newMap.values.sum;
  }

  Matrix setMatrixValue(Matrix matrix, int i, int j, double value) {
    final asLists = matrix.toList();
    final listOfLists = <List<double>>[];
    for (final list in asLists) {
      listOfLists.add(list.toList());
    }
    listOfLists[i][j] = value;
    return Matrix.fromList(listOfLists);
  }

  Vector setVectorValue(Vector vector, int i, double value) {
    final list = vector.toList();
    list[i] = value;
    return Vector.fromList(list);
  }

  Matrix mapToMatrix(Map<String, Map<String, double>>? map) {
    final matrix = Matrix.fromList(
        map?.values.toList().map((e) => e.values.toList()).toList() ?? [],
        dtype: DType.float64);
    return matrix;
  }

  Vector mapToVector(Map<String, double>? map) {
    final matrix = Vector.fromList(map?.values.toList() ?? [], dtype: DType.float64);
    return matrix;
  }

  // END HELPER FUNCTIONS

  void initVars() {
    activeGenes = genePools[determineGenePool()];
    final players = currentRound.info.groupMembers;
    tally = {for (final player in players) player: 0.0};
    unpaidDebt = {for (final player in players) player: 0.0};
    punishableDebt = {for (final player in players) player: 0.0};
    expectedReturn = {for (final player in players) player: 0.0};
    aveReturn = 0.0;
    scaledBackNums = {for (final player in players) player: 1.0};
    receivedValue = 0.0;
    investedValue = 0.0;
    ROI = gameParams.popularityFunctionParams.cKeep;

    // Adding this because sometimes underAttack is not getting initialized
    final popularities = currentRound.info.playerPopularities;
    underAttack = (activeGenes!.initialDefense / 100) * popularities[myPlayerName]!;
  }

  void updateVars() {
    activeGenes = genePools[determineGenePool()];

    tally.updateAll((key, value) =>
        value +
        (currentRound.info.tokensReceived?[key] ?? 0) *
            // currentRound.info.playerTokens *
            (prevPopularities?[key] ?? 0));
    tally[myPlayerName] = 0;

    punishableDebt.updateAll((key, value) => 0);

    final players = currentRound.info.groupMembers;
    for (final player in players) {
      if (tally[player]! < 0 && unpaidDebt[player]! < 0) {
        punishableDebt[player] = -max(unpaidDebt[player]!, tally[player]!);
      }
    }

    unpaidDebt.updateAll((key, value) => tally[key]!);

    for (final player in players) {
      if (player != myPlayerName) {
        scaledBackNums[player] = scaleBack(player);
      }
    }

    //   self.printT(player_idx, " scale_back: " + str(self.scaled_back_nums))

    receivedValue *= 1 - gameParams.popularityFunctionParams.alpha;
    final received = currentRound.info.tokensReceived;
    for (final player in players) {
      if (player == myPlayerName) {
        receivedValue += (received?[player] ?? 0) *
            (prevPopularities?[player] ?? 0) *
            gameParams.popularityFunctionParams.cKeep;
      } else if ((received?[player] ?? 0) < 0) {
        receivedValue += received![player]! *
            (prevPopularities?[player] ?? 0) *
            gameParams.popularityFunctionParams.cSteal;
      } else if ((received?[player] ?? 0) > 0) {
        receivedValue += received![player]! *
            (prevPopularities?[player] ?? 0) *
            gameParams.popularityFunctionParams.cGive;
      }
    }
    investedValue *= 1 - gameParams.popularityFunctionParams.alpha;
    investedValue +=
        clipVector(prevAllocations ?? {}).values.sum * (prevPopularities?[myPlayerName] ?? 0);
    if (investedValue > 0) {
      ROI = receivedValue / investedValue;
    } else {
      ROI = gameParams.popularityFunctionParams.cKeep;
    }
    if (ROI < gameParams.popularityFunctionParams.cKeep) {
      ROI = gameParams.popularityFunctionParams.cKeep;
    }
  }

  int determineGenePool() {
    if (numGeneCopies == 1) return 0;
    if (numGeneCopies != 3) {
      throw Exception('gene agent not configured for $numGeneCopies copies');
    }

    // compute the mean
    final m = currentRound.info.playerPopularities.values.sum / currentRound.info.numPlayers;
    // print(currentRound.info.playerPopularities);
    final ratio = currentRound.info.playerPopularities[myPlayerName]! / m;

    if (ratio > 1.25) {
      return 2;
    } else if (ratio < 0.75) {
      return 0;
    } else {
      return 1;
    }
  }

  double scaleBack(
    String quien,
  ) {
    if (currentRound.info.governmentRoundInfo.governmentPlayerNames?.contains(quien) ?? false) {
      //for now, don't scale back payments to the gov'ment
      return 1;
    }

    // consider scaling back if the other person is in debt to me
    // print('DEBT');
    // print(punishableDebt);
    if (punishableDebt[quien]! > 0) {
      final debtLimit = activeGenes!.otherishDebtLimits / 25;
      if (debtLimit > 0) {
        final denom = max(expectedReturn[quien]!, aveReturn) * debtLimit;
        if (denom == 0) {
          return 0;
        } else {
          final perc = 1.0 - (punishableDebt[quien]! / denom);
          if (perc > 0) {
            return perc;
          } else {
            return 0;
          }
        }
      }
    }

    return 1;
  }

  void initializeGenes() {
    // const assassinGenes =
    //     'genes_50_50_1_25_0_50_100_0_0_0_0_100_50_50_50_50_0_100_2_80_0_50_0_100_100_100_100_100_90_100_100_0_0_50_50_1_25_0_50_100_0_0_0_0_100_50_50_50_50_0_100_2_80_0_50_0_100_100_100_100_100_90_100_100_0_0_50_50_1_25_0_50_100_0_0_0_0_100_50_50_50_50_0_100_2_80_0_50_0_100_100_100_100_100_90_100_100_0_0';
    // const bullyGenes =
    //     'genes_50_20_50_50_25_50_50_100_50_80_50_70_20_20_50_50_0_50_30_60_20_0_0_50_100_100_100_100_100_90_0_100_0_50_20_50_50_25_50_50_100_50_80_50_70_20_20_50_50_0_50_30_60_20_0_0_50_100_100_100_100_100_90_0_100_0_50_20_50_50_25_50_50_100_50_80_50_70_20_20_50_50_0_50_30_60_20_0_0_50_100_100_100_100_100_90_0_100_0';

    // final topAgents = [
    //   //Old chat-less genes
    //   // 'gene_97_36_57_60_87_45_37_14_5_9_11_54_57_57_38_82_98_15_21_69_21_20_100_0_18_6_66_8_46_69_64_67_68_10_30_100_75_75_100_58_98_79_21_56_46_18_89_85_74_40_76_12_54_54_39_50_93_11_26_59_85_91_44_76_4_72_29_6_97_30_18_11_10_30_100_75_75_100_51_82_24_16_84_28_44_13_33_14_66_32_1_73_7_88_23_46_23_13_1_69_65_18_6_1_96_88_52_33_75_2_10_10_30_100_75_75_100',
    //   // 'gene_59_67_93_11_44_46_49_98_44_66_7_66_54_38_57_98_95_13_88_31_75_13_71_57_83_13_46_18_7_90_53_71_74_10_30_100_75_75_100_98_56_72_16_45_43_46_89_33_14_38_75_8_46_4_34_38_46_94_5_62_69_67_39_92_10_100_88_7_77_46_15_29_10_30_100_75_75_100_99_50_29_34_43_4_13_74_49_18_22_73_14_83_3_42_72_63_87_22_80_51_15_93_6_40_76_89_42_95_54_25_91_10_30_100_75_75_100',
    //   // 'gene_54_38_10_22_56_53_75_1_50_47_36_45_44_30_48_70_52_6_71_69_54_13_66_85_83_13_75_48_50_17_65_96_75_10_30_100_75_75_100_34_34_62_16_25_15_80_100_62_19_94_90_25_61_23_29_55_72_49_8_16_72_34_75_100_10_44_29_5_48_71_23_81_10_30_100_75_75_100_65_26_77_20_42_6_56_33_52_7_31_48_6_90_8_97_67_82_89_21_3_54_79_5_30_65_82_41_65_17_72_88_26_10_30_100_75_75_100',
    //   // 'gene_72_68_95_29_46_67_75_21_49_23_79_56_54_8_74_31_67_11_12_47_18_70_68_86_77_65_51_18_0_91_19_66_45_10_30_100_75_75_100_100_34_15_16_64_59_16_64_46_77_50_20_36_45_20_64_65_50_46_4_35_84_5_75_72_10_69_84_5_93_28_30_33_10_30_100_75_75_100_36_18_12_56_38_3_41_21_33_30_64_27_11_83_11_40_16_96_92_22_52_0_16_78_11_65_80_10_44_86_51_40_10_10_30_100_75_75_100',
    //   // 'gene_39_49_26_58_39_62_39_21_62_47_81_47_54_40_59_78_84_12_82_33_54_24_68_1_77_8_81_55_0_67_71_10_75_10_30_100_75_75_100_93_96_86_18_48_4_66_15_17_0_3_82_27_57_18_56_80_52_79_59_58_7_76_41_82_8_30_26_88_40_83_26_57_10_30_100_75_75_100_6_96_46_90_89_6_35_74_49_79_64_32_23_1_3_97_17_87_40_31_5_7_77_79_31_37_58_31_64_37_71_96_54_10_30_100_75_75_100',
    //   // 'gene_92_23_41_63_60_55_37_4_49_16_40_36_56_49_50_59_72_23_84_54_41_56_54_25_43_11_88_76_2_53_70_97_22_10_30_100_75_75_100_0_96_72_22_64_54_46_3_100_14_17_9_17_52_54_19_69_25_87_35_18_11_8_68_76_22_75_95_8_83_74_92_11_10_30_100_75_75_100_17_30_25_17_44_37_81_21_71_72_71_49_18_72_3_13_19_46_85_29_2_63_87_81_59_21_80_32_39_28_72_2_92_10_30_100_75_75_100',
    //   // 'gene_54_56_42_29_52_59_88_40_100_50_81_77_50_57_44_100_17_73_91_27_17_24_3_7_89_14_47_8_59_87_30_48_46_10_30_100_75_75_100_2_49_82_22_51_27_69_11_31_74_38_10_13_94_3_34_80_52_94_8_48_35_52_37_72_12_69_6_90_35_76_22_19_10_30_100_75_75_100_71_20_17_48_68_0_38_74_47_91_41_30_11_82_46_61_75_36_74_22_100_5_12_66_46_41_78_48_70_75_71_5_16_10_30_100_75_75_100',
    //   // 'gene_50_25_54_11_69_0_55_51_50_51_11_53_99_38_54_84_17_75_91_27_28_66_69_67_77_59_51_65_64_59_54_100_70_10_30_100_75_75_100_100_22_12_16_49_22_86_89_96_18_46_24_26_94_54_59_59_100_94_17_62_1_87_5_77_67_91_54_35_69_76_29_19_10_30_100_75_75_100_34_0_73_30_37_45_83_23_54_13_66_86_15_23_9_67_11_31_83_28_50_0_90_81_66_40_39_41_63_41_71_0_68_10_30_100_75_75_100',
    //   // 'gene_50_36_57_67_42_53_30_38_87_47_57_40_46_57_59_41_100_13_67_28_65_9_100_31_98_18_53_49_0_53_53_67_45_10_30_100_75_75_100_36_96_41_40_60_95_34_54_78_78_100_77_24_65_36_24_55_47_94_56_62_13_24_48_9_10_59_3_27_49_40_64_30_10_30_100_75_75_100_37_0_14_29_42_7_44_17_23_65_26_73_28_43_17_42_34_42_66_20_11_72_84_0_26_52_73_80_33_44_69_9_18_10_30_100_75_75_100',
    //   // 'gene_56_32_93_18_61_12_52_90_44_48_87_95_54_11_44_20_99_7_94_67_33_38_94_93_13_95_44_53_61_90_88_85_43_10_30_100_75_75_100_25_47_57_58_41_62_17_47_79_32_46_91_32_71_92_61_100_36_96_25_55_9_19_45_3_32_26_1_28_86_68_23_96_10_30_100_75_75_100_72_17_14_68_43_50_80_74_24_69_90_35_29_82_7_100_69_38_75_7_96_56_83_42_76_37_98_0_64_76_75_39_7_10_30_100_75_75_100',
    //   // 'gene_70_31_24_64_48_75_39_75_100_80_79_37_83_13_18_83_80_75_36_5_21_53_79_14_62_25_79_29_31_23_85_13_39_10_30_100_75_75_100_87_55_42_52_36_87_56_38_67_59_70_57_71_91_52_61_71_93_0_28_8_5_0_77_44_67_4_10_3_52_46_40_66_10_30_100_75_75_100_30_63_97_9_84_30_6_51_96_98_62_10_5_79_61_91_58_58_49_38_49_20_46_32_3_68_38_35_98_66_69_94_81_10_30_100_75_75_100',
    //   // 'gene_67_88_8_2_59_86_41_48_97_92_100_19_36_47_99_63_17_73_43_64_60_4_76_72_32_24_86_57_51_36_85_97_17_10_30_100_75_75_100_29_8_38_28_41_90_45_16_60_41_28_76_7_88_37_76_35_62_20_37_5_78_96_84_21_42_8_6_49_30_23_42_59_10_30_100_75_75_100_88_45_44_1_70_20_43_52_100_74_14_11_9_81_40_53_56_93_88_82_93_42_47_16_76_4_36_47_26_26_68_61_92_10_30_100_75_75_100',
    //   // 'gene_74_30_47_39_28_89_77_74_13_97_71_15_85_100_0_2_12_3_78_8_12_7_73_24_90_10_11_60_62_54_85_66_64_10_30_100_75_75_100_70_75_63_52_93_7_20_71_53_91_12_85_55_3_27_88_75_70_0_68_8_74_63_56_44_90_16_0_58_86_78_49_70_10_30_100_75_75_100_82_33_72_78_71_5_42_40_93_75_58_11_7_58_61_89_32_20_49_72_100_20_85_59_74_37_79_36_2_54_81_30_42_10_30_100_75_75_100',
    //   // 'gene_72_38_32_54_72_64_66_2_99_14_91_85_83_93_11_58_95_6_78_27_70_13_37_9_55_53_4_79_9_40_69_48_59_10_30_100_75_75_100_42_7_65_52_38_49_68_11_53_55_58_7_26_51_81_88_50_20_4_0_38_2_0_26_13_40_26_0_45_87_61_36_70_10_30_100_75_75_100_85_73_12_58_70_19_0_81_5_96_67_70_8_61_1_38_43_20_18_3_91_41_30_29_62_65_7_78_2_100_73_9_41_10_30_100_75_75_100',
    //   // 'gene_72_97_46_57_26_90_9_97_95_57_75_85_90_93_39_54_95_3_78_51_65_53_75_8_90_38_4_79_54_33_42_48_59_10_30_100_75_75_100_87_70_0_48_28_76_70_39_71_97_58_7_39_99_78_60_50_73_0_5_13_2_24_80_52_16_4_1_2_53_89_53_39_10_30_100_75_75_100_82_85_39_59_80_17_30_38_5_98_5_11_6_61_0_90_32_20_47_51_95_20_44_83_3_49_5_36_6_100_81_9_72_10_30_100_75_75_100',
    //   // 'gene_70_49_47_5_54_17_67_72_100_88_60_85_85_100_24_58_5_10_29_21_71_75_37_96_28_46_79_63_50_54_16_42_20_10_30_100_75_75_100_73_73_95_36_47_81_16_26_64_90_61_28_15_5_16_83_59_56_42_87_12_49_0_55_45_47_66_5_65_76_54_42_34_10_30_100_75_75_100_69_70_48_0_75_0_8_30_96_74_82_24_9_41_0_86_80_21_49_72_32_15_53_61_23_0_38_36_7_57_93_98_23_10_30_100_75_75_100',
    //   // 'gene_68_92_7_10_49_42_67_78_5_9_100_43_90_100_15_24_4_8_24_49_64_53_71_68_10_5_63_60_9_50_85_58_35_10_30_100_75_75_100_31_68_0_46_96_76_62_14_78_89_45_13_39_73_98_83_48_87_69_11_25_20_81_64_3_42_28_0_3_53_50_49_89_10_30_100_75_75_100_57_45_13_11_83_96_27_62_5_75_35_8_24_100_36_39_60_49_44_51_50_20_34_53_61_55_95_9_6_45_51_100_32_10_30_100_75_75_100',
    //   // 'gene_61_30_0_59_27_94_80_1_100_32_15_15_41_2_18_25_7_41_36_12_65_7_19_94_55_38_40_57_26_50_74_55_67_10_30_100_75_75_100_26_74_1_60_40_74_49_88_5_97_64_37_34_84_75_56_46_22_4_89_9_78_0_39_58_42_28_10_0_68_26_53_100_10_30_100_75_75_100_34_53_35_82_81_25_13_43_48_83_86_12_7_9_61_37_32_53_55_68_53_73_44_32_20_4_25_35_94_73_96_68_25_10_30_100_75_75_100',
    //   // 'gene_43_100_38_20_77_27_67_76_99_13_14_81_35_93_6_45_95_11_44_93_87_71_47_8_91_76_48_54_61_53_46_49_35_10_30_100_75_75_100_36_81_22_57_43_52_42_69_49_94_28_77_17_80_24_69_54_12_2_10_34_52_0_39_13_93_0_12_49_40_19_43_36_10_30_100_75_75_100_79_92_17_59_33_96_6_63_5_56_89_21_10_48_0_33_35_18_49_33_63_2_32_52_38_38_5_100_5_69_74_58_8_10_30_100_75_75_100',
    //   // 'gene_62_42_27_67_53_72_23_72_92_80_7_70_39_98_20_67_5_43_57_24_61_43_37_42_20_25_40_63_5_5_9_55_21_10_30_100_75_75_100_74_71_6_34_35_40_16_26_64_85_61_0_15_52_98_83_46_22_82_99_12_83_28_55_45_56_61_10_65_76_22_58_43_10_30_100_75_75_100_69_70_85_45_69_4_57_66_7_46_82_7_9_41_0_90_66_21_50_72_92_89_41_32_78_0_38_37_7_42_78_22_2_10_30_100_75_75_100',
    //   // 'gene_87_1_26_40_33_15_83_47_59_27_7_92_76_33_52_1_72_86_99_82_39_69_73_12_26_91_71_58_3_73_36_52_17_10_30_100_75_75_100_53_28_37_31_47_79_93_59_83_72_37_59_19_35_81_25_56_95_49_51_63_28_4_23_48_26_30_28_60_66_91_84_24_10_30_100_75_75_100_8_51_59_36_47_12_62_47_62_42_6_19_1_57_66_93_93_3_32_34_23_2_60_48_79_100_73_38_68_22_89_31_6_10_30_100_75_75_100',
    //   // 'gene_85_3_22_71_97_99_8_63_59_39_58_46_81_97_8_47_80_87_46_16_70_18_40_28_0_58_59_42_5_21_65_87_44_10_30_100_75_75_100_89_27_7_38_19_5_76_3_79_96_98_9_17_19_98_58_25_98_67_9_88_78_20_35_94_29_45_61_19_56_85_38_44_10_30_100_75_75_100_16_49_16_78_100_10_12_4_18_31_73_23_3_19_21_92_92_92_74_3_2_31_56_100_43_80_92_7_95_4_94_67_23_10_30_100_75_75_100',
    //   // 'gene_53_64_94_71_90_20_41_73_46_67_37_74_61_97_31_59_70_79_41_18_38_70_14_95_84_36_82_39_58_16_28_80_45_10_30_100_75_75_100_0_75_68_17_58_49_88_61_8_73_15_78_32_61_80_16_34_56_14_36_93_70_25_36_68_10_44_97_25_79_95_53_72_10_30_100_75_75_100_26_12_28_13_100_15_62_4_22_38_50_0_21_69_0_13_17_71_63_34_68_33_63_40_51_17_37_95_58_99_95_56_9_10_30_100_75_75_100',
    //   // 'gene_84_64_94_40_35_13_78_0_63_19_37_74_63_78_44_59_14_42_99_43_59_55_32_28_55_5_76_34_40_10_61_77_67_10_30_100_75_75_100_75_89_39_14_44_25_29_70_87_77_68_79_21_61_82_78_60_48_1_52_59_48_55_26_68_71_50_97_100_44_44_88_58_10_30_100_75_75_100_26_91_9_77_46_13_62_59_44_38_90_14_11_34_6_5_92_78_36_14_80_16_60_47_13_97_34_38_57_76_89_97_76_10_30_100_75_75_100',
    //   // 'gene_90_79_68_40_63_16_45_54_12_87_23_53_81_97_14_71_80_76_41_62_57_52_27_95_74_68_82_34_82_82_52_57_90_10_30_100_75_75_100_89_8_50_10_79_26_88_5_62_99_34_13_29_8_89_16_22_58_55_36_88_70_25_36_88_37_25_63_13_79_97_52_72_10_30_100_75_75_100_78_93_26_49_50_1_58_21_45_33_43_0_18_19_64_86_35_7_9_34_72_33_63_40_49_17_54_37_10_26_88_33_6_10_30_100_75_75_100',
    //   // 'gene_36_0_39_16_86_14_67_18_55_27_47_91_35_100_38_29_13_71_46_46_21_47_26_21_75_5_97_67_7_70_42_67_65_10_30_100_75_75_100_94_21_6_36_70_8_97_3_65_99_29_10_11_38_98_15_22_100_3_44_1_77_98_90_67_23_25_6_15_79_63_31_23_10_30_100_75_75_100_35_44_76_11_62_56_53_19_96_90_93_68_5_41_40_37_98_41_5_47_69_67_41_93_39_16_46_78_81_31_93_57_21_10_30_100_75_75_100',
    //   // 'gene_88_61_41_80_29_11_66_23_62_19_26_59_93_76_51_56_54_70_73_14_61_79_74_88_2_36_67_4_0_3_61_100_70_10_30_100_75_75_100_92_78_7_33_47_16_99_7_92_96_22_0_40_20_97_16_59_56_10_9_97_33_49_47_68_29_49_0_14_65_47_82_62_10_30_100_75_75_100_42_89_26_17_88_24_62_66_42_89_30_54_12_62_48_10_30_69_74_11_1_26_46_7_51_87_99_39_0_25_87_38_21_10_30_100_75_75_100',
    //   // 'gene_29_69_39_61_15_39_83_84_44_39_13_79_81_67_51_58_72_67_94_15_43_75_14_8_95_30_60_97_3_85_75_95_57_10_30_100_75_75_100_94_92_48_36_47_77_97_7_90_88_62_12_21_20_76_90_63_96_1_14_87_48_17_27_71_34_18_54_56_27_94_83_52_10_30_100_75_75_100_5_88_12_19_100_26_15_49_27_65_6_21_10_9_68_29_66_39_76_7_81_78_46_100_45_100_56_89_62_19_91_32_20_10_30_100_75_75_100',
    //   // 'gene_22_9_100_24_53_65_69_23_70_100_19_81_74_34_14_59_71_45_16_58_76_2_99_4_84_63_13_80_41_78_25_94_68_10_30_100_75_75_100_58_33_38_33_47_3_79_3_28_94_35_79_16_36_9_52_0_92_13_9_59_75_43_23_67_80_33_50_24_11_31_53_80_10_30_100_75_75_100_83_87_14_0_40_8_57_4_86_60_44_14_8_35_66_92_33_70_71_34_0_33_95_100_74_16_43_46_100_69_79_65_98_10_30_100_75_75_100',
    //   // 'gene_89_82_100_59_35_39_58_9_20_39_53_95_48_34_51_57_56_45_74_14_37_60_72_58_20_63_15_88_88_22_75_23_57_10_30_100_75_75_100_0_24_42_13_22_26_94_1_88_83_96_76_33_36_92_25_0_90_63_11_90_56_51_86_68_82_75_38_13_65_62_96_75_10_30_100_75_75_100_27_40_34_17_36_16_57_6_59_87_49_22_0_62_20_9_33_6_77_88_72_75_88_32_88_88_100_90_97_75_86_62_8_10_30_100_75_75_100',
    //   // 'gene_81_22_20_2_41_27_12_0_93_55_20_50_61_50_83_36_97_95_57_9_90_52_82_95_8_80_70_92_10_38_63_84_88_10_30_100_75_75_100_50_15_95_54_39_99_11_26_71_81_83_99_11_79_14_75_12_64_94_46_29_47_8_26_54_71_24_23_76_88_82_26_55_10_30_100_75_75_100_100_62_13_12_62_13_67_51_48_98_35_1_0_76_13_40_50_31_89_6_20_95_26_79_12_10_20_31_35_62_99_30_45_10_30_100_75_75_100',
    //   // 'gene_61_37_79_19_29_33_64_0_42_63_53_5_11_85_51_29_90_84_90_5_65_48_52_71_44_53_80_23_49_27_27_83_61_10_30_100_75_75_100_53_94_12_25_35_60_38_95_67_64_63_15_11_75_31_71_38_16_88_27_11_57_70_38_88_8_34_77_10_68_93_29_27_10_30_100_75_75_100_65_3_14_100_70_8_81_26_73_85_24_1_6_45_60_58_24_7_91_6_48_95_28_10_23_70_100_11_86_10_68_91_23_10_30_100_75_75_100',
    //   // 'gene_63_3_32_2_23_64_100_77_33_93_94_78_20_85_78_16_84_0_79_8_90_6_60_67_8_53_99_58_50_31_39_50_57_10_30_100_75_75_100_68_71_44_75_5_94_13_54_37_90_34_24_12_32_10_71_44_35_76_27_22_42_91_53_96_69_43_97_96_47_74_43_28_10_30_100_75_75_100_43_28_100_29_56_0_50_60_66_28_55_1_13_67_34_59_3_70_92_21_47_96_25_78_19_34_60_95_54_67_75_19_5_10_30_100_75_75_100',
    //   // 'gene_46_0_12_0_25_55_92_0_77_93_85_59_61_17_95_54_80_63_0_0_44_6_44_5_8_45_96_87_41_28_2_54_7_10_30_100_75_75_100_47_26_84_47_35_48_44_99_31_88_65_10_7_77_14_84_38_38_18_42_22_53_94_21_15_92_47_100_83_24_90_42_26_10_30_100_75_75_100_57_37_86_100_79_55_79_2_62_89_31_1_7_45_38_47_0_55_38_25_48_74_2_9_19_22_98_36_54_54_70_87_22_10_30_100_75_75_100',
    //   // 'gene_75_37_51_13_81_65_98_12_18_93_91_28_17_5_79_57_94_0_12_77_95_42_58_47_2_61_87_93_14_12_95_26_60_10_30_100_75_75_100_64_75_26_38_72_74_19_24_78_99_96_78_0_35_22_83_77_42_88_34_43_37_53_51_98_18_33_90_62_44_89_72_59_10_30_100_75_75_100_5_38_91_6_71_100_32_55_28_57_58_0_9_46_9_9_21_7_81_78_10_96_40_69_44_73_81_30_90_6_74_85_18_10_30_100_75_75_100',
    //   // 'gene_81_37_56_83_81_44_99_0_75_65_89_62_5_60_69_17_93_20_53_61_78_80_10_77_10_44_100_26_46_41_10_83_71_10_30_100_75_75_100_66_26_73_71_62_21_1_32_35_12_49_41_11_21_31_71_45_57_90_20_98_76_16_28_82_93_26_43_26_47_85_42_31_10_30_100_75_75_100_88_37_93_39_63_51_22_43_6_28_81_38_4_45_7_0_24_62_28_21_47_77_48_53_20_74_88_72_80_6_76_97_15_10_30_100_75_75_100',
    //   // 'gene_96_61_49_14_57_5_100_6_9_28_87_31_1_60_83_8_20_85_97_32_85_66_47_49_71_56_73_58_74_39_4_85_62_10_30_100_75_75_100_52_83_52_48_39_17_32_30_23_82_49_90_0_100_24_71_96_19_32_9_30_83_72_63_61_16_7_21_66_21_71_56_98_10_30_100_75_75_100_39_61_100_12_54_60_84_18_85_57_58_65_4_44_11_10_57_5_93_59_54_73_37_31_30_70_26_30_34_4_83_97_34_10_30_100_75_75_100',
    //   // 'gene_34_22_5_48_80_66_46_18_77_4_20_24_59_55_11_49_56_15_100_68_90_23_68_62_27_53_67_54_53_45_8_37_52_10_30_100_75_75_100_50_20_95_45_20_20_13_26_31_100_7_83_10_79_34_53_51_61_94_2_61_8_5_26_99_5_20_67_62_88_81_39_89_10_30_100_75_75_100_38_62_100_84_62_95_76_44_22_98_30_0_0_76_55_5_63_25_88_24_41_75_36_9_49_29_20_31_87_8_93_65_81_10_30_100_75_75_100',
    //   // 'gene_73_3_15_63_25_45_99_57_37_93_64_5_1_85_76_80_55_56_81_8_65_13_1_53_75_50_100_58_49_89_39_85_67_10_30_100_75_75_100_47_92_93_56_30_15_7_23_12_40_34_41_27_32_15_67_6_41_88_32_59_84_75_62_38_71_83_98_42_43_85_39_33_10_30_100_75_75_100_45_28_77_29_59_5_94_58_5_52_39_0_8_45_12_16_3_70_89_21_42_92_30_96_20_71_60_95_60_0_42_86_15_10_30_100_75_75_100',
    //   // 'gene_20_27_14_0_7_61_2_12_86_66_21_78_61_37_81_80_72_19_92_58_74_94_30_43_0_57_0_85_46_54_10_61_89_10_30_100_75_75_100_61_83_23_75_49_28_73_39_39_100_93_18_11_55_4_78_10_13_71_59_51_58_32_37_90_27_17_22_26_5_100_59_33_10_30_100_75_75_100_68_60_81_17_63_71_65_72_85_76_30_28_4_100_95_2_97_11_31_28_44_96_43_61_27_80_61_3_82_13_80_45_36_10_30_100_75_75_100',
    //   // 'gene_23_96_8_36_72_43_95_59_22_53_70_18_16_90_27_10_100_47_75_5_22_75_47_23_20_30_87_79_34_69_52_61_55_10_30_100_75_75_100_30_71_26_81_54_19_58_25_100_8_79_26_1_38_4_74_84_64_89_86_68_75_25_68_41_39_76_39_26_56_61_62_68_10_30_100_75_75_100_10_59_96_30_65_32_100_28_61_6_100_56_19_20_0_75_27_100_88_14_94_12_78_64_16_24_100_88_69_75_48_7_92_10_30_100_75_75_100',
    //   // 'gene_79_90_67_28_72_43_68_17_53_0_68_18_29_86_27_4_100_46_86_87_87_66_76_23_17_30_85_95_97_66_24_37_75_10_30_100_75_75_100_75_10_84_21_97_45_92_25_98_8_65_3_42_45_4_83_57_33_95_86_84_78_4_81_49_61_49_93_98_59_61_62_5_10_30_100_75_75_100_92_59_91_78_68_29_62_28_61_6_51_49_19_20_14_41_96_100_61_65_97_48_78_46_30_54_23_36_38_75_100_7_80_10_30_100_75_75_100',
    //   // 'gene_40_6_64_59_68_100_31_78_60_26_78_40_71_36_77_30_93_33_74_8_53_69_33_29_67_17_94_55_21_36_65_31_59_10_30_100_75_75_100_99_48_50_20_92_19_59_25_27_12_85_18_5_47_53_95_0_54_60_28_73_73_19_62_61_90_79_93_21_94_87_67_9_10_30_100_75_75_100_42_62_92_29_84_1_0_6_12_65_46_28_15_39_38_53_19_100_47_15_32_9_35_51_16_70_34_61_66_72_54_89_76_10_30_100_75_75_100',
    //   // 'gene_81_81_29_97_43_11_93_70_21_99_94_37_20_23_77_20_93_85_18_6_24_42_33_80_59_77_21_15_26_23_53_92_75_10_30_100_75_75_100_57_44_62_95_37_31_25_15_96_91_76_25_29_40_20_71_5_16_95_36_81_74_32_81_44_0_52_83_67_75_52_57_15_10_30_100_75_75_100_42_64_92_48_66_46_3_4_90_58_96_49_27_51_29_14_96_0_97_16_82_42_31_84_2_22_34_46_41_72_93_18_89_10_30_100_75_75_100',
    //   // 'gene_28_52_86_79_77_61_35_50_21_56_32_29_28_44_33_62_77_52_74_18_15_70_60_85_55_86_81_37_26_70_2_35_40_10_30_100_75_75_100_49_48_57_17_37_47_67_28_100_30_62_32_29_95_77_73_0_55_60_7_78_31_24_72_69_53_31_88_54_21_94_61_70_10_30_100_75_75_100_83_41_83_25_77_21_54_40_44_3_47_40_20_18_18_22_1_10_97_14_97_45_8_85_49_72_53_100_14_74_95_7_90_10_30_100_75_75_100',
    //   // 'gene_24_80_67_62_73_61_99_88_95_53_88_40_28_57_25_58_47_47_84_83_82_60_44_28_9_88_88_28_26_19_70_56_75_10_30_100_75_75_100_92_32_26_78_46_45_67_78_89_27_7_3_44_43_17_38_7_22_15_41_51_0_9_36_69_36_72_93_65_50_61_64_63_10_30_100_75_75_100_19_41_82_68_76_30_12_33_10_58_48_47_34_80_37_23_22_78_60_15_20_55_72_39_45_73_20_100_36_38_46_68_75_10_30_100_75_75_100',
    //   // 'gene_68_97_61_27_40_5_49_90_23_82_67_35_22_43_29_89_71_85_14_100_66_73_49_32_54_37_6_82_34_19_17_5_62_10_30_100_75_75_100_98_71_26_20_45_19_94_23_100_95_71_27_37_80_11_1_17_54_41_0_74_73_20_53_37_57_83_22_25_32_39_46_18_10_30_100_75_75_100_89_54_44_39_68_82_7_60_90_100_32_5_28_43_4_91_20_7_48_14_93_45_15_21_5_80_55_38_29_70_40_7_87_10_30_100_75_75_100',
    //   // 'gene_86_29_22_100_66_93_30_88_71_0_68_65_96_90_46_20_93_66_43_9_16_66_29_86_59_24_87_82_26_63_65_30_100_10_30_100_75_75_100_5_48_60_67_60_20_96_45_98_34_70_18_12_46_9_76_85_53_15_49_100_12_59_82_59_37_37_79_17_18_93_78_52_10_30_100_75_75_100_86_43_83_16_48_21_2_7_20_56_53_55_24_50_35_80_94_81_48_79_100_45_18_94_82_100_33_47_39_76_75_30_85_10_30_100_75_75_100',
    //   // 'gene_31_37_12_92_64_5_2_71_89_69_70_30_36_21_77_18_77_45_18_59_20_2_28_89_21_22_15_28_85_43_74_8_63_10_30_100_75_75_100_36_85_63_22_88_27_63_60_24_78_53_10_22_32_57_72_81_60_29_0_22_75_24_77_32_30_72_88_69_6_62_29_82_10_30_100_75_75_100_78_48_83_89_84_47_2_4_13_56_48_42_13_74_35_66_52_77_9_13_2_85_0_94_46_76_32_2_69_14_34_23_76_10_30_100_75_75_100',
    //   // 'gene_6_74_15_100_78_5_24_47_60_100_21_86_13_90_27_6_91_58_51_0_93_64_81_22_61_10_89_20_34_76_63_74_47_10_30_100_75_75_100_50_48_63_43_96_24_90_0_92_0_19_65_41_80_2_80_0_53_36_19_82_75_3_17_94_57_36_91_14_0_49_79_88_10_30_100_75_75_100_79_54_83_20_79_36_2_60_24_58_50_40_27_50_38_74_90_59_45_90_100_21_94_49_22_84_97_44_36_70_48_28_68_10_30_100_75_75_100',
    //   // 'gene_52_96_91_23_92_40_57_11_62_99_82_46_68_26_55_20_100_94_35_29_15_64_79_84_0_82_81_25_38_0_99_43_24_10_30_100_75_75_100_11_85_17_12_78_10_86_13_83_33_93_83_12_61_23_33_12_0_63_39_74_50_36_14_44_19_58_70_62_77_67_6_79_10_30_100_75_75_100_21_0_87_10_83_17_65_25_79_69_20_7_6_74_54_34_22_33_93_25_100_28_46_34_20_77_67_27_6_20_59_37_53_10_30_100_75_75_100',
    //   // 'gene_48_58_34_96_92_39_49_20_65_74_93_77_72_62_0_55_3_35_55_47_20_99_83_86_16_80_38_88_79_3_50_90_27_10_30_100_75_75_100_68_29_49_70_77_45_42_14_37_35_74_29_4_34_63_33_97_66_0_49_82_35_59_17_16_53_40_0_88_49_85_3_36_10_30_100_75_75_100_17_28_60_29_68_15_57_24_76_69_100_19_11_14_51_45_31_64_69_82_100_48_79_3_14_54_100_18_36_66_90_46_26_10_30_100_75_75_100',
    //   // 'gene_93_28_11_64_8_28_66_60_79_53_60_36_57_95_25_9_99_35_58_20_27_79_24_49_87_20_72_62_84_1_50_51_34_10_30_100_75_75_100_34_98_81_68_41_42_28_8_4_37_14_82_12_31_100_29_10_16_78_28_76_20_59_73_69_22_81_96_98_40_43_13_79_10_30_100_75_75_100_100_55_70_29_70_17_65_18_78_64_26_41_7_39_48_75_69_36_87_72_95_18_23_21_46_29_84_91_31_22_59_45_54_10_30_100_75_75_100',
    //   // 'gene_52_57_35_69_96_78_82_37_11_56_14_94_64_84_27_3_25_41_59_26_20_80_81_84_14_73_62_46_34_28_46_49_31_10_30_100_75_75_100_39_85_45_81_78_65_94_59_32_6_68_88_6_31_72_82_97_87_26_3_97_13_36_55_7_16_76_71_82_77_51_75_33_10_30_100_75_75_100_96_0_89_98_51_58_41_8_75_79_75_32_7_64_59_79_54_68_98_79_19_16_72_23_24_17_71_59_69_90_69_46_2_10_30_100_75_75_100',
    //   // 'gene_57_3_35_69_94_78_35_32_79_17_14_94_9_98_33_41_68_34_24_67_20_80_24_84_11_28_16_59_89_67_99_42_17_10_30_100_75_75_100_84_85_36_60_86_65_97_24_82_81_68_10_6_35_90_82_36_6_96_3_55_87_36_14_30_16_100_16_53_74_51_2_33_10_30_100_75_75_100_65_0_82_98_51_32_19_26_75_65_100_38_9_47_48_88_54_5_83_16_68_57_76_25_88_62_64_59_70_18_69_51_30_10_30_100_75_75_100',
    //   // 'gene_49_0_81_29_8_42_86_28_79_71_84_94_62_51_93_39_20_40_56_9_15_65_12_81_1_57_50_68_97_86_84_94_24_10_30_100_75_75_100_58_82_89_63_47_39_88_15_78_91_57_10_56_100_34_39_4_16_34_20_74_18_38_13_26_4_18_79_62_11_74_7_78_10_30_100_75_75_100_3_45_63_19_60_34_69_19_76_69_31_12_3_13_46_19_68_30_88_13_2_100_59_1_98_32_75_58_69_93_75_46_77_10_30_100_75_75_100',
    //   // 'gene_66_29_27_84_19_76_8_20_23_62_19_77_72_28_29_74_20_35_62_85_15_87_97_97_58_80_90_14_79_2_49_53_31_10_30_100_75_75_100_53_20_86_70_12_73_12_34_79_64_68_42_7_94_34_87_97_18_0_89_62_35_94_63_66_17_14_51_88_49_79_3_27_10_30_100_75_75_100_100_32_87_19_79_29_59_4_18_95_86_41_11_73_44_68_72_64_69_10_86_50_78_2_63_54_75_18_33_89_72_49_12_10_30_100_75_75_100',
    //   // 'gene_75_20_30_64_9_57_100_28_56_11_35_76_65_31_19_78_56_31_84_26_87_88_29_38_8_75_90_21_87_60_85_12_54_10_30_100_75_75_100_53_78_26_25_44_55_33_14_82_84_63_4_7_53_72_91_0_6_79_15_43_90_39_14_66_69_70_74_96_80_59_0_90_10_30_100_75_75_100_37_12_45_37_94_27_71_23_86_94_85_3_3_64_66_62_100_63_84_27_37_80_35_30_16_78_75_72_71_95_72_47_34_10_30_100_75_75_100',
    //   // 'gene_43_38_35_27_2_45_100_69_17_28_43_36_68_31_25_72_86_9_69_54_19_20_3_33_58_70_92_44_62_0_83_62_24_10_30_100_75_75_100_71_75_82_68_42_37_42_86_68_0_40_8_4_77_65_92_86_25_28_17_23_93_55_31_70_14_79_24_52_81_60_11_27_10_30_100_75_75_100_100_99_59_86_94_25_71_25_0_71_100_19_4_51_54_69_60_81_95_92_100_0_26_10_97_78_75_48_63_32_72_73_97_10_30_100_75_75_100',
    //   // 'gene_61_29_10_58_79_31_98_79_22_66_86_76_67_51_25_91_20_35_40_14_14_95_47_86_22_96_15_26_83_2_40_45_41_10_30_100_75_75_100_45_9_61_5_47_38_81_15_46_35_56_0_39_26_19_95_20_3_0_33_76_20_95_14_63_17_11_77_8_36_100_14_43_10_30_100_75_75_100_100_76_79_19_63_91_19_26_74_79_78_44_6_71_52_24_85_1_67_31_87_57_54_73_22_53_66_23_68_10_72_51_29_10_30_100_75_75_100',
    //   // Chat genes
    //   // 'genes_100_78_55_56_70_16_26_18_42_13_83_95_62_87_82_57_22_21_0_57_14_1_73_17_54_70_64_15_27_68_15_50_89_86_7_32_18_78_26_97_69_19_88_55_76_13_80_78_9_61_78_80_57_75_22_74_39_46_19_37_75_56_47_30_25_33_65_45_38_76_10_28_49_37_66_50_23_43_5_100_96_41_0_6_85_99_73_16_14_64_95_1_44_21_10_6_56_57_80_39_17_74_71_50_0_89_42_94_78_97_15_28_61_64_23_33_62',
    //   // 'genes_29_29_2_56_99_50_55_64_92_35_82_10_62_10_82_24_53_66_60_96_32_47_73_91_49_54_61_20_1_23_64_29_75_73_47_29_25_78_29_82_63_1_69_78_22_98_41_53_20_73_27_28_39_20_42_60_43_98_54_30_3_39_6_47_10_26_33_54_19_61_59_31_54_18_50_97_21_6_39_27_71_55_4_0_43_81_66_36_100_37_0_57_5_21_83_10_55_37_60_72_4_25_85_59_47_60_80_45_83_0_40_4_93_60_69_22_68',
    //   // 'genes_14_50_55_66_70_50_42_36_37_22_82_99_68_5_80_44_45_98_87_62_85_38_73_51_59_56_39_48_0_72_96_80_91_10_91_80_23_6_95_96_59_19_67_77_28_4_5_86_7_26_55_84_40_19_52_81_39_19_17_83_91_56_7_100_2_23_6_12_48_23_92_100_43_18_66_58_5_77_92_85_8_41_6_5_20_86_11_19_46_50_63_81_5_39_48_2_57_100_17_30_70_50_20_18_41_66_46_69_21_68_72_64_61_63_98_33_22',
    //   // 'genes_81_73_29_24_59_79_11_19_76_30_86_85_17_5_19_49_25_25_71_15_78_18_13_70_85_56_60_48_96_69_94_79_42_88_100_33_84_89_97_97_22_71_94_65_40_0_58_53_58_46_74_36_22_28_95_79_63_79_22_57_99_6_34_45_6_80_91_12_22_28_90_65_67_78_95_51_36_43_71_19_73_11_59_6_21_69_87_52_94_66_62_25_4_83_8_13_25_73_58_68_92_0_98_33_43_28_46_88_8_55_41_6_54_45_45_4_55',
    //   // 'genes_56_92_43_56_14_50_92_86_37_31_85_14_76_5_70_57_75_23_0_13_32_26_73_93_70_54_12_84_27_95_55_46_90_75_100_28_7_10_84_100_88_0_61_63_98_37_20_50_10_100_27_55_59_27_25_8_33_100_31_19_3_62_91_26_6_37_11_78_64_36_59_15_12_78_0_60_32_10_62_66_82_41_54_3_34_99_4_53_31_75_22_95_55_25_48_19_25_37_74_34_30_98_20_18_33_66_43_45_23_0_6_61_26_9_87_34_68',
    //   // 'genes_61_21_66_60_62_16_50_21_47_59_8_14_75_66_85_38_51_74_32_60_4_35_56_47_72_60_25_98_26_18_47_46_80_70_92_29_2_4_79_10_47_81_69_84_51_0_86_58_88_73_77_14_62_55_25_68_82_50_91_20_75_55_7_95_2_33_12_82_61_37_16_29_11_77_59_60_14_31_68_100_88_52_16_13_21_91_69_25_10_35_75_26_96_60_88_100_25_23_80_67_13_4_18_35_5_33_9_78_74_93_62_64_46_45_29_8_3',
    //   // 'genes_58_50_54_60_70_74_42_60_97_24_4_28_65_70_70_52_44_34_58_38_40_38_90_93_58_56_47_53_18_44_43_29_92_100_43_68_7_85_9_93_74_34_62_78_43_37_55_48_33_72_55_33_76_20_81_0_67_91_27_41_59_40_96_13_76_78_11_4_19_49_90_39_81_77_67_50_14_93_38_64_8_42_6_3_72_55_35_57_93_92_71_61_96_24_65_85_18_100_73_34_65_2_94_100_41_66_35_7_5_82_10_4_19_48_54_26_55',
    //   // 'genes_14_32_18_66_16_53_93_70_95_29_82_52_61_10_17_43_55_100_4_41_79_97_81_51_42_71_61_44_51_4_0_98_92_75_43_33_81_36_79_88_59_60_10_79_13_0_78_53_11_59_28_85_90_16_43_21_92_98_26_54_72_3_48_99_22_27_55_12_47_47_90_36_81_82_70_66_16_21_36_100_1_34_4_3_17_27_66_23_88_52_59_1_54_49_28_16_89_87_16_39_43_0_91_20_44_96_76_52_34_4_33_24_44_62_98_37_68',
    //   // 'genes_61_85_10_60_40_59_25_63_13_24_83_78_87_42_80_56_95_21_4_22_63_20_81_66_44_56_18_27_81_33_100_78_60_88_39_33_82_80_29_25_47_6_65_40_73_8_83_78_64_99_60_16_35_74_16_56_68_57_17_41_99_62_64_33_6_30_86_30_14_45_74_59_46_71_63_18_72_43_69_59_76_70_24_8_59_90_66_83_12_34_63_81_22_17_22_56_32_74_12_4_0_5_39_40_18_28_86_1_17_1_66_16_51_64_98_52_70',
    //   // 'genes_9_39_51_72_61_56_50_55_40_23_81_54_4_73_85_57_22_98_46_93_67_19_0_42_49_95_44_25_94_72_95_50_15_48_96_15_82_89_78_50_68_10_89_67_74_12_16_58_86_72_52_37_53_16_25_59_37_99_26_41_82_67_85_67_23_78_52_58_4_11_16_58_66_43_55_54_67_38_38_97_75_12_18_35_79_81_90_16_13_8_72_6_55_24_73_21_58_74_80_93_13_50_38_79_36_27_49_4_0_92_66_21_59_45_69_88_11',
    //   // 'genes_34_73_76_93_22_43_92_64_97_66_4_92_33_5_71_38_21_44_89_36_67_78_57_46_0_82_59_9_90_68_14_45_84_54_17_30_19_13_94_9_89_77_98_91_65_0_23_44_64_29_64_95_86_23_90_11_71_39_11_6_68_56_91_26_55_45_52_32_0_87_47_35_11_74_53_5_7_93_42_66_75_0_38_1_19_83_8_16_36_74_34_43_88_4_31_98_13_95_16_66_8_0_100_92_84_92_41_55_26_13_10_4_82_9_73_26_14',
    //   // 'genes_8_11_15_50_3_53_37_72_11_12_42_56_99_67_20_87_31_19_85_57_19_41_69_58_62_37_25_49_29_100_2_45_31_75_28_89_91_11_2_81_74_14_17_79_67_99_83_78_48_49_82_96_59_19_32_21_40_98_10_35_75_54_5_44_73_30_89_85_4_14_93_44_82_81_57_98_14_77_36_61_24_73_15_6_58_28_68_80_56_72_61_45_15_49_28_41_19_96_21_71_4_45_91_49_47_28_35_52_8_0_81_61_42_45_88_25_22',
    //   // 'genes_100_8_72_56_14_7_49_38_100_33_7_24_99_42_54_12_92_72_66_15_28_64_52_69_71_37_24_25_34_62_92_18_88_78_66_48_81_13_39_28_69_63_57_53_33_8_21_40_10_51_41_100_41_23_73_98_75_96_67_41_95_58_7_8_2_33_82_78_61_8_6_24_49_53_8_86_42_41_71_88_76_13_46_50_84_55_70_3_100_74_60_45_51_21_8_100_59_23_95_39_44_61_40_96_90_16_35_51_88_2_10_95_62_65_58_10_59',
    //   // 'genes_100_78_62_7_64_67_43_19_44_28_59_56_48_66_34_39_54_100_7_15_84_66_8_22_61_37_47_31_88_62_69_46_91_88_66_74_88_12_39_35_29_67_66_64_43_6_19_42_39_25_74_82_22_28_8_53_29_80_67_22_34_54_81_11_47_39_78_82_3_72_97_24_10_77_10_55_56_43_36_91_78_64_47_13_85_58_73_72_99_48_64_4_90_83_32_15_90_30_73_72_24_47_44_50_90_92_86_23_95_60_10_61_49_45_87_5_33',
    //   // 'genes_61_21_62_27_14_40_87_86_84_31_16_83_87_41_79_19_76_44_25_56_67_26_7_56_70_82_59_8_27_65_83_46_85_75_17_68_80_57_29_91_30_8_74_65_43_12_63_22_3_97_100_22_32_65_72_47_40_85_64_19_84_58_82_36_14_66_97_63_59_91_55_91_11_77_1_18_64_43_31_100_19_36_70_0_58_100_95_4_63_13_69_95_0_86_43_13_46_49_79_76_8_0_54_91_39_100_81_32_23_92_30_26_54_100_58_88_59',
    //   // 'genes_100_13_15_60_37_53_42_38_11_71_88_97_76_70_70_52_44_74_0_75_46_38_90_56_92_60_44_54_63_10_43_82_65_100_69_74_91_30_0_93_96_29_56_72_69_0_53_53_85_71_55_33_59_23_78_0_37_62_10_28_59_40_100_44_76_29_86_5_31_83_54_35_59_33_98_61_14_38_71_90_8_69_1_13_72_46_82_7_93_92_71_78_81_3_43_41_59_100_73_93_65_2_86_46_49_98_39_75_21_92_10_61_19_45_33_25_19',
    //   // 'genes_64_80_67_7_40_79_42_63_88_26_49_48_65_71_78_56_95_68_32_95_36_66_79_66_56_11_25_27_8_37_22_58_63_93_39_33_27_80_29_70_36_83_88_66_22_0_74_78_68_70_59_57_67_74_99_94_48_57_27_42_72_18_64_33_6_46_86_30_53_21_93_71_77_77_74_18_56_43_73_19_23_70_6_12_85_14_8_44_12_1_63_81_52_21_12_63_20_95_15_14_62_5_15_36_49_93_46_55_9_1_71_25_16_48_75_74_27',
    //   // 'genes_10_17_50_45_41_60_84_31_81_69_72_54_99_9_85_38_5_74_32_75_80_41_12_43_58_50_30_25_74_33_0_49_90_46_48_75_82_19_78_28_77_61_85_24_81_9_16_44_31_29_59_90_67_26_90_78_86_96_26_41_50_35_48_28_0_78_20_73_53_96_52_37_51_18_58_93_11_93_13_90_29_58_4_6_36_55_82_56_31_60_78_82_81_24_39_46_90_59_16_68_63_50_65_100_25_22_41_75_21_81_80_27_11_61_69_19_57',
    //   // 'genes_61_23_69_60_40_100_22_35_47_56_11_23_20_25_70_57_52_74_5_52_3_41_56_56_57_56_25_48_13_18_94_28_100_80_96_75_35_78_77_25_47_60_100_61_44_9_81_53_23_2_45_92_65_20_16_1_67_58_15_93_75_67_4_36_6_25_97_46_57_47_50_24_46_43_36_49_68_96_69_68_74_72_51_5_97_54_76_40_3_63_60_53_9_21_71_56_61_53_74_43_4_2_42_54_93_28_76_94_8_97_33_65_61_60_60_22_68',
    //   // 'genes_90_26_65_60_14_78_57_38_82_12_85_56_75_87_20_69_33_5_32_57_19_35_81_52_62_54_25_49_77_14_38_29_80_50_91_85_2_4_81_10_74_55_69_84_30_0_83_78_8_98_44_6_59_25_25_68_23_50_68_67_75_54_5_35_6_20_12_5_65_37_97_44_11_81_59_49_39_39_69_53_2_73_15_4_58_91_65_39_61_72_72_81_15_26_27_95_18_47_63_67_30_50_34_46_23_28_9_66_8_55_10_66_79_47_60_26_21',
    //   // 'genes_9_85_11_60_55_51_92_12_93_58_81_59_95_51_70_0_44_74_5_63_3_35_82_56_19_68_50_62_71_18_94_100_87_49_7_75_27_89_35_63_47_60_69_67_44_9_83_98_65_73_27_63_65_20_14_0_40_97_56_39_75_3_97_17_63_25_87_68_31_47_59_51_70_19_73_66_67_29_71_86_23_72_17_5_56_10_5_57_100_50_75_61_96_24_43_100_7_87_27_81_25_2_95_18_96_88_86_94_6_93_33_5_49_42_13_52_24',
    //   // 'genes_58_59_72_56_69_53_56_60_97_22_2_59_72_71_19_40_0_65_58_44_45_37_16_93_58_65_60_9_53_44_62_45_26_92_25_51_7_85_29_98_69_87_63_67_33_9_86_50_7_37_55_61_76_20_89_10_31_100_27_42_73_8_96_44_10_75_11_4_65_29_91_16_54_77_49_51_29_66_38_100_77_41_6_53_62_45_35_5_11_93_9_1_96_2_33_15_19_93_73_34_65_64_20_100_37_95_35_71_88_82_84_4_91_48_98_88_55',
    //   // 'genes_58_50_54_49_61_79_91_91_97_79_93_54_42_71_70_34_42_4_36_53_83_26_16_93_58_65_50_9_56_69_60_27_91_46_46_34_7_61_81_11_74_88_62_67_33_15_86_50_33_26_56_90_80_26_89_10_36_100_67_41_50_8_7_44_0_27_85_4_14_46_100_14_93_74_55_47_68_64_38_64_75_41_6_3_34_55_35_5_26_98_80_61_75_74_17_39_59_100_17_98_25_98_20_32_22_66_86_77_17_82_84_2_26_46_67_46_58',
    //   // 'genes_29_21_18_66_43_60_94_88_69_23_79_25_66_27_52_44_58_23_71_99_18_69_10_50_62_59_41_31_27_41_60_73_87_8_98_31_91_83_0_88_69_0_40_67_67_3_20_54_64_72_82_96_65_29_90_3_45_13_15_40_94_34_48_86_95_25_19_69_55_29_95_37_13_35_70_5_97_75_91_100_35_7_4_4_39_26_8_93_10_57_64_1_49_24_28_100_29_57_59_19_13_79_88_45_95_100_86_89_95_66_84_85_46_45_87_26_14',
    //   // 'genes_29_8_2_60_37_63_55_50_11_59_37_10_62_14_70_49_58_11_5_63_3_47_0_91_42_54_25_19_13_18_95_25_89_49_47_33_75_89_79_25_51_54_67_56_22_9_4_98_20_73_55_44_39_28_63_1_67_65_17_38_75_97_2_15_22_25_87_12_42_52_52_80_46_43_53_49_16_96_72_10_71_72_4_3_56_54_66_36_100_63_60_56_5_22_43_100_2_76_30_51_90_40_85_59_89_98_80_94_9_4_40_4_28_48_63_52_68',
    //   // 'genes_57_20_62_56_100_53_50_38_12_33_30_24_72_71_83_44_31_72_66_41_28_61_9_66_71_71_50_25_13_62_92_3_41_82_80_53_81_33_41_10_30_11_57_56_39_0_5_89_57_70_52_100_41_23_73_60_48_99_69_38_95_54_12_49_2_92_85_75_55_13_96_24_70_82_73_86_56_39_59_91_76_38_12_50_8_11_2_3_100_74_58_1_56_21_12_63_88_18_19_81_84_22_95_60_62_96_1_85_69_2_37_4_62_46_73_3_58',
    //   // 'genes_10_23_54_62_100_98_80_50_47_56_11_80_68_51_84_69_52_21_43_51_67_57_55_47_81_50_50_23_5_72_46_28_83_80_100_85_79_78_87_86_30_14_77_61_88_9_81_53_81_2_45_95_67_26_41_53_37_93_26_74_95_42_4_34_51_56_97_82_57_47_50_49_15_19_31_56_71_29_13_100_19_25_72_34_97_98_73_37_97_30_75_52_52_21_8_97_61_100_18_7_4_40_18_55_93_98_76_79_17_52_13_7_64_3_60_96_68',
    //   // 'genes_29_39_24_70_70_98_22_31_43_37_11_83_35_51_81_57_50_90_27_52_2_51_98_51_81_65_60_48_76_42_56_28_90_80_42_85_81_78_29_82_89_25_100_63_17_9_81_53_8_24_28_97_24_63_42_54_82_88_64_74_50_65_4_26_22_25_90_12_58_29_55_22_54_77_10_56_72_35_70_100_54_46_16_3_0_83_71_16_97_26_77_30_10_21_74_92_55_57_19_56_4_51_18_55_49_98_76_83_25_97_47_5_88_60_60_22_68',
    //   // 'genes_3_73_6_27_100_48_52_5_97_23_29_3_27_33_50_45_44_99_2_55_77_62_12_51_59_98_56_21_30_42_66_48_89_10_35_16_78_30_95_89_50_64_17_64_28_8_17_87_25_30_22_96_60_20_49_13_90_93_31_38_1_21_100_29_18_30_44_72_52_21_100_66_12_10_34_100_14_41_48_19_85_72_51_5_85_6_80_7_4_63_93_97_51_11_69_41_73_49_73_97_30_0_62_95_91_91_49_14_28_48_62_61_52_17_87_88_24',
    //   // 'genes_10_67_18_91_66_88_62_88_69_23_88_47_72_42_52_54_25_23_32_99_61_69_83_53_59_49_41_48_53_69_45_45_91_10_7_30_28_99_17_88_47_5_17_50_33_1_59_91_82_72_70_85_65_32_27_86_81_47_68_40_21_97_96_87_78_7_96_82_45_44_10_53_55_82_70_25_89_96_31_100_88_7_57_55_17_55_8_72_10_57_62_1_51_21_28_95_27_25_93_39_65_2_91_79_90_91_46_55_71_70_62_61_13_62_79_29_19',
    //   // 'genes_59_67_43_58_98_88_59_22_27_9_89_47_72_87_56_36_65_98_32_61_61_18_79_47_16_49_53_82_22_51_66_46_85_10_94_29_7_43_17_86_27_1_0_79_61_97_86_96_59_75_70_82_22_35_14_0_83_47_68_39_75_62_94_33_78_7_48_46_73_66_10_53_73_77_54_85_18_96_67_100_52_45_9_2_52_51_13_72_22_100_80_4_53_21_27_95_63_30_69_50_63_10_44_13_90_91_86_52_71_46_62_76_52_62_79_13_34',
    //   // 'genes_77_18_37_61_97_23_94_35_39_26_88_60_87_9_82_52_26_5_90_52_78_26_98_25_85_71_27_84_90_68_82_46_0_50_43_31_91_10_39_81_90_60_57_84_25_0_17_53_85_72_41_82_65_75_25_3_29_90_22_39_100_60_48_47_15_21_88_13_48_5_93_66_13_88_58_86_12_63_48_100_74_7_86_13_43_58_91_51_99_69_77_25_51_10_100_43_88_15_73_30_35_0_70_50_43_27_89_55_9_55_17_57_51_37_69_26_59',
    //   // 'genes_9_26_44_56_64_56_54_60_43_35_90_56_78_21_51_39_42_23_85_78_75_67_8_47_88_37_9_19_88_33_64_43_88_10_43_83_86_95_39_96_58_61_65_63_50_11_19_89_57_25_62_99_83_28_78_98_27_80_54_13_75_54_84_11_47_34_6_32_48_86_54_31_60_86_55_0_97_93_71_71_64_13_46_17_51_83_87_95_98_77_68_4_51_80_8_43_59_96_0_38_4_47_44_50_90_29_86_75_1_0_6_63_49_45_87_5_33',
    //   // 'genes_59_60_62_66_0_56_19_70_88_13_88_56_72_10_71_22_5_100_0_44_29_38_91_70_72_65_60_31_0_26_98_31_30_98_82_29_79_13_79_70_69_8_57_82_34_8_87_92_20_37_24_87_39_34_90_57_44_100_26_16_79_65_9_44_0_75_44_12_79_29_96_16_73_51_75_0_29_89_66_100_75_62_6_51_41_14_5_61_46_93_60_1_81_2_12_15_6_100_89_48_13_40_40_60_43_25_31_75_29_4_42_2_91_67_84_13_14',
    //   // 'genes_34_3_6_19_61_50_52_89_11_23_26_61_27_42_50_44_20_74_66_33_42_46_1_13_43_36_56_45_32_99_56_54_89_62_94_21_81_37_95_30_29_73_85_79_70_8_17_31_30_4_72_87_56_20_49_23_39_68_72_36_6_52_100_44_100_27_82_58_3_52_3_35_11_10_45_61_32_41_37_100_73_5_10_5_80_54_66_7_98_63_59_94_58_92_8_41_2_49_70_45_30_19_82_50_20_53_49_94_1_0_62_61_45_45_11_87_59',
    //   // 'genes_38_29_18_66_14_80_58_22_100_10_82_13_32_10_57_44_92_72_64_62_86_9_90_70_85_52_39_44_0_72_76_18_92_100_25_48_75_6_31_81_62_63_67_56_59_4_53_53_10_58_79_95_39_47_12_62_26_14_87_41_91_58_7_8_7_34_78_12_48_23_97_24_69_53_53_58_26_77_69_90_8_5_15_53_0_81_66_57_46_93_63_1_24_49_11_41_59_100_95_27_70_50_25_59_73_15_80_47_14_8_68_2_50_65_58_5_22',
    //   // 'genes_40_10_46_87_100_40_84_35_83_26_25_56_75_9_70_52_5_74_79_75_18_39_12_56_22_67_25_25_90_33_100_28_84_14_43_73_82_19_82_28_65_53_66_67_74_9_33_12_81_29_44_85_65_70_10_100_71_99_27_55_4_65_33_26_73_33_9_75_53_29_52_26_42_32_58_52_14_37_100_94_100_55_100_1_15_55_82_68_31_69_95_36_100_73_8_43_91_67_73_11_84_85_44_44_38_100_56_52_98_82_13_27_11_70_69_29_16',
    //   // 'genes_99_62_62_27_86_40_87_22_84_19_90_16_87_23_19_49_76_25_68_10_30_39_83_47_85_37_62_86_27_69_7_79_85_86_17_52_80_57_94_100_46_13_74_65_51_9_58_22_57_94_74_36_22_65_95_79_40_14_62_36_94_58_31_92_15_66_44_85_58_92_52_91_76_82_55_86_41_59_71_94_79_36_9_3_84_96_97_9_12_34_73_94_52_86_25_98_25_45_61_47_100_0_18_91_0_100_81_94_8_6_10_26_68_45_45_21_11',
    //   // 'genes_29_73_29_27_100_88_91_7_97_34_86_100_69_33_85_49_44_25_68_81_76_64_12_51_36_37_60_43_30_42_7_79_91_51_100_27_80_87_85_92_22_30_85_56_35_10_58_87_33_46_74_36_22_17_95_79_90_79_62_23_82_58_16_29_18_30_87_80_58_21_90_39_12_82_51_100_41_58_16_16_85_72_46_16_88_55_87_9_14_66_77_4_51_11_69_95_25_49_61_47_96_0_62_50_92_91_44_14_29_6_41_4_49_61_87_21_68',
    //   // 'genes_40_17_46_38_62_15_92_35_92_41_81_56_100_9_15_38_5_74_0_75_67_47_65_47_73_71_59_25_26_33_2_28_90_62_100_83_82_19_37_28_47_61_71_63_81_9_16_78_23_54_44_32_65_75_78_79_85_98_27_41_72_67_3_37_5_25_20_75_57_29_17_18_17_37_58_56_16_29_37_100_96_5_4_6_35_87_73_40_31_60_9_61_100_21_39_100_25_59_18_14_4_74_84_100_1_90_76_79_8_82_33_27_64_61_64_18_15',
    //   // 'genes_100_50_46_41_62_16_26_18_80_41_62_56_75_12_70_38_5_21_76_57_18_39_12_6_59_71_88_25_30_70_15_29_80_95_7_32_82_36_78_28_86_19_99_55_76_9_16_78_74_61_78_92_57_75_21_78_44_100_27_41_75_35_14_32_2_26_65_27_67_29_17_28_54_37_58_52_23_10_37_94_96_45_4_6_85_55_70_16_14_23_25_1_81_20_27_43_90_57_73_39_87_39_44_35_0_100_41_75_78_88_84_27_11_64_69_19_18',
    //   // 'genes_34_42_69_65_75_44_98_91_60_60_27_60_62_27_12_52_58_74_76_61_75_15_81_73_85_70_21_45_90_29_64_58_82_77_40_30_77_10_74_57_9_81_96_89_22_4_19_12_4_43_48_84_84_35_90_97_54_100_31_39_100_62_98_49_83_25_4_75_51_33_55_79_79_95_31_51_16_37_91_14_76_62_16_1_39_1_82_36_6_5_72_94_45_21_100_100_19_80_11_4_66_4_78_45_43_13_86_82_88_0_40_46_35_9_60_13_15',
    //   // 'genes_98_29_2_60_16_51_4_49_47_29_81_52_4_21_82_57_22_98_32_41_85_47_0_42_39_81_25_44_0_18_27_50_92_48_96_15_33_11_78_9_69_87_96_67_13_4_83_53_67_59_28_83_39_18_16_4_46_93_18_54_75_3_48_36_22_30_59_46_43_47_16_97_55_82_55_54_68_29_38_100_1_2_18_4_78_4_66_16_77_5_78_6_5_24_94_56_58_87_80_72_64_50_50_20_91_30_57_82_8_92_84_21_44_62_87_32_67',
    //   // 'genes_77_18_20_64_0_53_92_35_97_27_95_60_66_44_68_54_21_5_89_40_38_19_79_42_59_82_45_9_89_64_14_45_79_14_59_73_16_13_31_81_89_60_69_84_65_0_69_58_64_43_64_82_57_75_25_100_29_41_11_39_68_60_38_25_15_25_4_29_61_8_93_28_13_75_3_51_54_37_42_53_74_7_86_6_43_15_8_51_48_78_93_56_52_21_31_100_55_90_35_44_63_0_70_92_39_99_69_83_5_100_85_68_46_45_87_26_68',
    //   // 'genes_100_9_72_27_70_12_54_22_92_17_86_47_68_10_19_0_36_98_68_38_37_89_79_17_58_68_47_55_81_70_65_97_91_86_99_32_36_41_97_100_76_30_88_77_76_15_59_99_43_93_54_91_41_19_29_74_85_100_27_63_100_54_78_87_19_0_86_100_58_36_52_35_55_95_67_18_68_18_65_100_70_62_23_8_52_90_66_93_7_79_94_42_97_21_59_63_25_75_36_6_24_66_44_34_90_64_38_52_44_8_74_25_70_62_98_79_64',
    //   // 'genes_61_65_88_27_70_79_81_77_29_49_84_36_72_87_82_25_60_21_30_39_6_26_79_70_16_50_54_86_63_51_0_29_80_46_50_62_39_43_90_86_32_14_99_79_61_9_83_64_59_29_63_83_20_26_16_0_84_43_26_31_10_67_48_33_51_25_99_45_55_96_45_72_51_75_54_85_24_37_13_100_29_44_98_33_88_8_41_61_98_100_80_1_53_24_8_20_63_100_79_50_21_15_100_15_23_45_86_94_95_0_62_68_52_46_41_13_69',
    //   // 'genes_40_16_18_51_70_14_50_23_92_28_78_47_72_39_90_42_59_98_90_86_61_18_80_60_60_53_11_48_85_70_47_57_15_54_7_45_28_12_17_100_29_1_0_68_45_15_59_40_63_75_70_82_22_35_27_77_42_47_19_39_82_62_9_47_1_7_9_82_4_88_54_53_10_79_33_25_83_96_16_87_88_45_5_3_85_51_8_77_99_74_49_23_51_18_70_95_19_90_73_95_73_0_85_79_5_28_43_52_20_60_62_61_67_62_39_28_34',
    //   // 'genes_10_16_6_60_77_47_42_34_27_71_88_61_78_24_56_52_22_78_84_38_46_38_47_40_59_56_44_53_70_14_43_29_65_10_48_74_4_30_4_93_69_14_53_79_43_37_53_46_85_76_72_94_60_89_81_3_40_42_34_28_96_40_52_13_76_31_4_69_52_4_77_97_20_33_66_52_14_10_67_20_58_45_23_6_15_76_73_66_93_5_71_79_11_24_100_0_18_96_35_34_76_49_94_46_42_98_46_68_19_92_10_29_46_64_33_33_50',
    //   // 'genes_14_8_6_60_40_79_52_21_81_23_29_3_29_94_50_54_44_74_66_10_80_46_16_39_64_98_56_64_85_64_2_46_89_14_48_21_82_30_90_38_74_10_85_24_30_10_80_89_33_30_15_90_67_26_90_23_86_96_55_35_6_29_100_28_100_27_47_99_3_96_52_37_11_10_98_97_56_41_14_100_74_58_58_5_85_54_73_2_100_32_77_94_55_26_28_49_59_49_78_45_30_50_86_39_50_21_86_94_95_45_84_61_93_51_69_82_69',
    //   // 'genes_61_30_62_27_99_72_87_35_84_28_86_88_62_10_82_54_76_66_45_10_32_39_72_91_42_54_59_19_27_69_83_29_75_78_47_33_80_57_79_100_0_54_74_56_47_98_20_53_3_73_60_22_32_65_10_24_43_98_31_30_73_54_81_22_22_29_44_85_43_23_92_35_79_42_53_18_69_43_29_10_79_37_0_3_58_96_66_36_100_34_51_94_5_86_94_93_55_49_30_72_93_0_61_91_47_98_80_94_25_4_30_4_28_45_63_88_11',
    //   // 'genes_100_29_20_56_62_11_82_36_37_10_82_95_32_10_20_57_22_21_0_57_18_38_70_51_62_70_39_23_2_14_15_29_80_9_91_59_75_22_29_83_56_34_67_59_76_4_53_78_82_61_28_95_39_75_84_1_39_14_15_16_91_62_7_97_6_30_10_12_67_23_97_28_79_37_53_51_23_10_67_90_8_45_12_6_85_81_73_57_14_72_63_1_28_20_27_41_56_100_80_35_70_50_71_60_73_89_80_47_14_4_72_28_50_64_69_32_16',
    //   // 'genes_10_8_68_93_68_63_66_60_97_71_3_97_65_94_70_61_1_74_100_75_71_41_14_56_14_64_25_20_63_33_60_82_83_71_67_21_2_80_95_96_96_11_56_68_66_10_80_50_25_75_63_60_96_17_52_11_31_58_55_38_75_19_100_44_7_29_84_4_36_37_54_66_93_80_98_51_5_96_68_64_96_40_7_2_83_83_82_40_27_98_77_79_52_67_48_17_59_100_17_43_14_2_39_13_41_98_92_30_21_82_10_61_82_13_50_32_55',
    //   // 'genes_61_8_72_11_40_79_22_63_11_17_83_97_65_42_70_38_95_77_1_95_71_41_79_66_88_56_25_20_63_29_100_84_8_88_39_33_80_58_95_25_69_1_88_66_69_0_17_89_25_29_55_57_67_18_65_99_31_57_55_38_97_18_100_33_10_5_86_30_31_52_54_16_59_27_63_61_56_53_73_66_75_70_57_12_85_83_82_7_10_74_77_78_46_24_43_63_24_18_1_45_62_5_42_35_36_24_3_52_21_82_71_61_51_48_13_52_99',
    //   // 'genes_57_42_62_7_61_12_92_22_88_27_49_17_62_27_12_87_72_74_60_50_36_66_81_43_85_9_21_48_8_29_56_58_63_93_40_58_77_33_27_72_38_86_17_84_22_18_74_73_68_43_59_96_61_68_90_24_85_60_19_42_72_62_98_8_0_46_14_75_8_12_92_79_76_35_29_51_56_87_91_14_23_38_16_12_40_2_11_36_7_1_72_7_18_24_100_0_19_80_24_14_66_5_15_45_43_93_47_83_83_3_40_20_40_46_60_74_15',
    //   // 'genes_25_15_55_50_77_51_26_34_95_71_59_25_68_24_17_43_22_21_4_13_79_97_42_61_59_9_9_16_51_68_66_81_83_75_43_66_4_29_29_41_69_75_96_79_79_2_78_46_29_29_67_84_60_19_47_3_40_98_74_22_94_52_48_99_2_27_4_85_47_42_90_97_81_77_70_15_23_21_70_100_58_29_23_4_17_76_66_66_92_52_20_1_59_49_100_21_78_96_35_34_43_0_91_44_94_96_46_68_19_62_19_4_46_41_63_33_31',
    //   // 'genes_35_25_18_50_70_11_37_94_11_12_85_56_99_87_85_87_31_5_23_55_84_19_98_42_59_99_61_49_66_68_93_50_15_50_92_32_82_11_97_40_74_60_92_74_42_9_59_78_9_28_75_96_60_23_16_53_71_97_19_28_77_54_5_87_29_32_89_68_4_14_97_24_78_73_46_52_16_44_67_0_4_72_15_4_58_6_73_57_61_99_71_30_46_26_27_41_18_47_67_5_30_7_34_49_22_28_29_57_9_92_9_61_79_53_36_26_22',
    //   // 'genes_11_21_88_49_62_80_59_94_49_93_93_61_43_24_76_52_60_93_30_61_84_97_98_70_59_6_54_22_66_95_98_33_16_92_28_33_82_24_29_11_29_63_21_74_66_15_59_54_77_37_54_84_60_27_30_59_36_98_19_36_94_58_7_87_28_31_61_69_70_37_52_24_76_73_55_100_42_87_46_90_24_32_86_9_34_45_73_87_98_93_60_30_24_1_13_20_59_36_76_95_0_51_39_96_19_87_85_82_8_0_9_65_64_46_37_26_71',
    //   // 'genes_10_17_49_54_41_82_85_63_81_69_84_49_99_42_80_56_95_66_32_95_59_41_16_66_56_56_26_23_81_64_22_46_90_46_39_33_82_89_90_26_74_1_88_24_30_9_79_78_64_43_59_57_67_26_90_99_86_61_27_35_97_18_48_38_8_78_86_30_55_98_52_16_51_77_63_25_72_43_23_64_76_70_58_2_85_30_66_40_100_32_78_35_55_24_20_63_58_18_16_68_63_5_61_35_49_33_86_94_9_1_71_25_46_46_69_52_27',
    //   // 'genes_98_50_66_46_23_47_50_21_53_13_83_97_87_66_85_38_51_21_59_56_84_39_80_47_85_60_11_19_26_51_76_82_80_65_92_29_17_40_73_96_23_75_88_46_47_0_83_44_88_73_77_83_57_23_21_0_79_97_27_55_75_53_4_44_76_33_65_1_48_8_54_29_67_77_66_85_14_39_37_100_88_43_29_11_12_58_42_16_6_50_53_4_96_60_31_96_23_18_65_7_8_0_43_35_46_25_86_75_21_93_62_24_41_14_69_68_31',
    //   // 'genes_7_65_43_50_3_53_81_71_50_13_84_23_72_49_82_63_55_18_89_13_54_15_79_45_0_37_41_86_25_51_66_45_80_63_28_29_7_43_50_93_61_14_71_79_67_9_78_91_48_72_63_90_65_38_16_0_84_98_27_30_75_67_31_44_18_25_19_85_60_8_93_32_13_75_57_98_18_39_84_100_49_45_9_6_52_28_52_37_10_97_80_4_53_16_33_100_68_96_21_17_21_0_91_13_23_45_76_49_83_92_62_68_42_41_88_20_16',
    //   // 'genes_89_12_88_90_69_50_89_41_97_37_85_14_81_13_81_0_60_23_30_96_76_28_46_70_72_50_54_39_96_98_55_29_83_45_100_28_3_14_87_41_87_10_62_63_98_9_83_12_26_27_59_55_50_26_25_8_41_100_74_40_10_62_96_26_51_48_100_73_64_36_52_15_54_83_72_100_24_93_66_93_79_37_62_28_88_17_41_3_31_75_69_76_53_24_8_20_68_30_87_16_28_25_100_60_22_99_92_30_21_2_40_25_26_46_41_26_69',
    //   // 'genes_57_32_63_66_100_53_50_70_92_25_61_52_32_71_83_77_44_100_1_61_28_38_83_51_75_43_50_55_13_30_90_3_63_90_79_33_40_6_79_70_30_43_57_77_37_4_22_89_67_70_56_87_39_24_9_60_48_57_26_16_79_65_12_33_6_33_85_5_78_23_94_24_70_32_73_17_44_90_59_86_71_17_12_3_5_11_5_58_100_100_97_1_52_73_12_91_7_18_94_84_25_24_95_59_46_54_80_85_29_4_42_64_16_62_84_49_58',
    //   // 'genes_57_15_24_26_61_24_93_91_43_37_78_58_39_73_80_34_27_4_31_61_83_39_33_4_25_65_21_52_85_69_55_27_43_86_46_73_81_61_82_25_1_78_17_82_17_4_16_48_80_24_28_55_21_28_42_2_82_88_62_19_6_65_78_30_0_27_85_64_66_9_60_22_54_72_72_56_19_35_69_90_100_48_58_3_37_11_87_56_94_30_50_33_75_74_80_92_52_30_88_56_25_48_100_32_49_56_9_77_25_92_24_61_88_60_14_88_59',
    //   // 'genes_61_90_10_58_0_55_92_49_93_79_81_3_95_51_85_57_58_68_32_92_28_38_5_43_58_71_25_19_67_8_99_46_68_66_96_73_27_89_12_63_84_60_96_67_44_3_83_98_65_72_59_88_58_18_2_0_33_100_17_39_79_3_7_36_6_30_14_100_15_29_96_66_46_65_98_66_65_39_71_86_91_17_53_3_40_6_5_67_100_52_75_61_52_22_5_100_18_87_16_66_66_5_95_100_44_25_73_55_88_5_33_5_93_50_26_27_58',
    //   // 'genes_10_96_15_50_68_63_9_60_97_71_84_85_62_70_17_61_58_70_32_63_75_98_69_45_59_51_25_21_67_39_63_30_31_75_100_92_2_29_95_96_8_14_17_67_30_99_78_91_69_72_82_36_84_19_90_21_40_96_19_95_75_96_77_33_7_25_94_81_47_39_93_24_93_77_24_98_5_36_65_67_59_5_7_3_83_81_52_83_10_98_13_76_20_67_48_13_19_100_17_17_63_18_39_39_41_23_92_30_83_82_19_24_46_50_88_32_55',
    //   // 'genes_100_90_37_90_67_60_54_49_37_34_81_56_84_9_80_57_36_98_5_56_3_72_81_47_60_34_25_48_30_18_3_97_91_93_96_15_82_57_78_97_47_1_17_77_42_5_51_98_64_72_56_87_25_21_16_79_67_96_12_41_97_13_85_72_6_7_86_46_14_41_16_97_55_75_55_18_68_43_69_100_91_13_18_4_2_1_73_19_14_70_94_52_51_24_8_21_58_75_36_95_66_4_38_75_93_17_23_58_8_47_84_21_51_45_35_33_69',
    //   // 'genes_100_85_37_90_70_60_91_52_37_69_85_14_84_100_81_36_50_98_91_58_76_39_100_47_67_34_67_98_71_33_5_97_24_39_36_48_34_50_29_94_90_73_17_63_43_18_87_96_21_75_59_83_25_24_25_79_85_64_21_10_50_60_78_21_1_29_86_77_73_26_74_63_54_75_51_56_25_43_69_88_75_13_21_3_2_83_70_4_94_70_94_52_85_21_8_100_25_75_36_76_22_51_44_62_47_61_20_1_9_8_28_94_51_62_64_13_23',
    //   // 'genes_34_78_62_62_70_67_52_91_57_33_27_28_48_20_35_52_58_87_79_38_75_18_38_70_22_70_61_46_66_64_64_86_15_78_14_30_89_12_74_9_68_48_84_89_71_4_19_42_60_36_49_82_84_92_49_97_71_57_19_55_100_57_9_47_22_30_78_76_3_33_48_26_6_75_72_83_56_37_69_100_76_62_9_1_86_57_73_82_99_43_13_79_45_1_80_43_19_25_76_59_9_0_34_50_36_18_86_56_95_92_40_61_59_60_55_26_11',
    //   // 'genes_100_8_48_93_40_56_80_50_11_5_81_97_75_94_84_38_5_21_3_51_71_57_12_56_88_60_50_20_22_33_44_82_83_71_69_21_79_48_87_89_96_11_56_46_69_0_95_55_27_75_55_60_67_23_82_11_33_100_23_38_7_42_85_28_10_29_78_82_27_52_54_64_53_35_98_61_24_95_13_66_75_48_1_13_56_18_73_3_31_74_77_24_52_3_5_97_59_98_1_61_44_2_86_51_30_92_3_82_21_52_11_61_26_9_67_82_69',
    //   // 'genes_58_16_37_65_83_53_54_7_11_23_29_3_27_94_58_44_20_72_64_43_80_97_21_41_59_64_82_10_87_31_93_18_91_92_66_48_81_60_95_30_69_80_64_79_30_17_17_54_25_46_76_82_22_20_49_23_35_86_87_45_6_16_100_8_100_28_82_19_59_49_100_31_54_84_98_94_56_41_16_91_74_64_68_53_86_54_63_7_33_64_77_89_57_83_13_41_71_49_95_39_30_61_86_60_48_20_86_19_95_45_62_57_60_45_13_31_71',
    //   // 'genes_61_4_43_56_40_79_25_63_41_17_50_49_72_42_83_56_95_72_31_95_32_45_73_66_52_51_25_53_81_33_22_75_3_56_34_33_87_80_29_25_63_1_4_78_39_11_83_50_2_61_63_28_67_24_46_99_37_57_54_41_97_18_4_37_10_28_86_30_55_21_52_31_54_77_57_55_72_43_63_27_79_70_71_48_85_37_49_95_12_32_0_62_23_21_83_19_21_18_40_48_4_25_20_35_7_66_86_42_9_2_20_25_26_48_71_52_31',
    //   // 'genes_81_73_62_22_70_79_52_51_57_28_86_28_71_20_19_57_25_84_7_96_84_18_65_70_67_6_47_4_66_64_45_46_15_88_40_74_5_27_31_35_91_74_5_65_38_15_69_42_39_25_52_82_57_70_25_79_71_70_22_20_30_57_9_45_56_80_88_12_22_72_54_62_10_79_10_51_36_43_69_100_73_64_5_6_21_59_9_52_96_98_62_31_90_10_8_59_29_23_73_66_24_2_100_33_43_92_40_88_95_60_44_61_59_45_58_27_55',
    //   // 'genes_95_60_37_56_97_44_21_67_88_39_97_78_31_29_84_13_50_72_90_96_32_18_98_55_85_60_56_31_88_68_4_79_88_50_36_25_78_10_97_5_90_65_57_58_38_0_87_96_85_31_41_87_53_20_31_82_38_90_19_71_80_21_96_28_20_34_86_18_48_72_95_66_54_82_69_0_15_87_71_100_43_61_16_13_80_32_87_0_99_50_67_25_51_10_33_43_19_15_73_34_33_98_43_60_82_27_35_78_95_55_10_55_93_37_55_81_59',
    //   // 'genes_61_12_66_46_69_16_49_49_29_23_81_14_76_65_81_38_50_21_30_57_89_7_78_47_52_50_56_19_26_18_17_36_80_46_92_58_12_17_93_41_30_85_100_79_55_9_83_16_88_73_59_85_22_52_21_0_82_100_23_5_7_53_48_28_76_33_65_82_48_67_59_29_51_79_72_93_24_37_64_90_29_44_29_30_15_58_41_25_14_32_73_95_96_60_84_100_25_18_80_16_17_5_71_35_22_25_40_79_95_0_62_64_26_45_39_68_31',
    //   // 'genes_58_50_54_52_52_93_54_60_97_56_7_59_31_51_84_57_52_65_27_52_64_51_16_98_58_82_60_48_76_44_2_28_94_80_14_85_7_78_29_93_74_87_100_61_48_9_86_53_76_43_45_92_60_20_89_53_37_92_22_74_50_9_4_38_20_78_97_50_57_46_50_24_93_80_36_51_72_93_35_64_79_41_6_3_15_100_76_35_3_98_75_53_9_21_48_85_59_56_17_34_24_98_20_55_45_66_89_79_0_82_33_4_26_48_60_22_55',
    //   // 'genes_61_67_22_91_40_79_25_22_92_17_49_49_65_42_77_56_59_21_31_61_61_18_79_66_87_49_25_27_81_70_18_78_91_83_39_33_28_59_17_52_47_1_88_46_69_1_59_78_64_64_59_82_67_74_16_82_48_47_13_41_21_18_67_87_80_7_86_82_73_8_10_53_69_77_63_25_72_43_16_87_76_13_57_48_85_30_8_40_12_36_63_81_48_21_20_63_24_30_11_3_62_0_39_35_49_30_86_52_9_1_67_25_67_48_75_33_27',
    //   // 'genes_58_21_46_27_43_56_94_55_83_41_89_56_66_14_81_21_60_21_25_56_6_26_14_44_59_72_54_24_27_69_60_28_92_40_59_58_91_19_78_25_30_2_100_67_89_10_81_54_64_30_44_83_65_28_90_0_67_99_15_39_94_33_48_28_51_25_19_72_73_29_48_30_13_81_60_52_63_77_91_90_35_5_2_3_88_8_46_9_10_32_57_56_49_24_100_100_55_57_79_16_44_79_100_15_87_12_86_94_95_0_40_25_46_46_58_26_69',
    //   // 'genes_40_16_46_42_62_14_84_77_86_28_78_54_77_39_70_38_52_74_81_60_18_24_0_6_60_71_88_55_47_69_47_62_15_95_43_75_99_19_31_43_77_62_66_67_43_9_16_40_23_25_44_82_65_70_29_78_71_99_19_65_50_35_13_47_0_2_20_37_4_29_54_23_10_35_58_52_16_80_37_94_40_5_5_6_56_55_82_16_31_60_9_27_81_73_39_43_94_55_73_14_73_39_85_63_41_28_40_60_21_60_10_27_12_61_69_19_44',
    //   // 'genes_40_21_62_7_62_80_59_47_100_28_58_28_73_42_76_12_60_93_7_38_29_18_88_44_61_6_11_10_66_95_73_29_17_93_96_14_89_96_31_11_29_48_84_64_62_15_69_54_77_25_44_87_21_27_18_53_71_57_6_22_72_57_12_29_1_2_18_100_3_41_52_14_12_42_54_97_42_43_36_100_75_64_58_53_85_58_87_87_99_48_60_39_90_1_12_20_59_23_69_72_44_0_24_98_19_17_73_56_8_0_40_65_69_43_58_31_71',
    //   // 'genes_51_39_18_58_43_79_93_52_48_15_81_10_62_73_81_65_50_94_33_97_39_66_73_56_83_71_21_32_92_72_55_53_92_48_42_28_77_10_31_97_47_1_86_60_98_18_76_89_15_19_63_84_62_72_63_69_82_97_23_41_53_67_80_3_4_25_60_75_56_26_55_77_16_77_31_25_32_66_14_21_1_34_57_3_89_79_87_16_100_24_52_94_95_22_29_56_96_29_86_14_22_79_94_26_27_97_9_55_55_8_8_20_39_62_29_68_11',
    //   // 'genes_41_42_69_14_43_34_94_22_76_28_78_60_70_23_82_69_72_84_60_52_67_61_85_46_46_6_59_44_13_70_96_44_82_88_100_22_77_37_79_25_59_54_72_56_33_9_80_54_25_43_48_83_63_29_88_24_85_93_19_39_20_96_81_29_14_25_6_75_43_8_93_35_11_35_29_97_16_77_82_14_29_32_72_11_58_2_5_0_11_0_72_56_18_21_100_97_56_80_73_14_66_91_38_64_47_92_7_83_20_2_36_9_50_9_45_19_15',
    //   // 'genes_98_67_33_65_43_12_94_22_74_23_78_16_69_5_12_47_22_25_68_61_78_65_81_47_30_37_60_48_59_96_7_58_82_50_100_52_86_89_97_67_23_81_89_40_22_0_58_53_57_49_72_36_63_34_95_79_85_100_62_39_99_58_98_87_15_34_82_80_61_12_93_42_76_35_29_86_16_54_71_10_23_32_46_16_84_2_87_39_6_70_72_94_18_21_100_10_19_80_61_47_96_4_19_45_0_100_42_83_10_6_40_20_40_61_57_16_15',
    //   // 'genes_57_4_37_56_97_87_50_70_92_39_88_52_32_45_71_52_80_100_0_50_78_38_83_51_85_37_50_48_88_25_98_31_63_93_81_30_67_6_39_5_90_43_57_56_30_0_22_73_20_70_28_87_53_20_84_82_64_89_26_16_79_14_12_47_0_34_66_82_48_71_95_66_70_51_73_86_15_86_66_100_24_61_72_3_84_11_5_0_100_100_97_70_52_10_27_43_19_98_73_81_13_2_90_60_43_98_35_16_96_55_42_57_16_61_7_52_58',
    //   // 'genes_9_39_63_11_62_53_84_41_93_30_26_56_46_71_14_39_42_74_28_64_28_73_14_47_85_68_50_48_13_60_90_3_93_48_44_73_40_9_84_70_30_14_59_59_22_4_5_89_8_70_56_92_72_68_9_80_67_60_15_43_18_65_12_33_2_33_25_74_55_29_93_14_5_33_69_17_56_42_48_78_45_43_4_6_61_11_7_57_90_66_59_1_6_24_22_100_25_18_50_81_87_22_44_18_43_93_46_85_8_3_38_2_51_46_87_33_58',
    //   // 'genes_41_9_72_14_14_34_58_22_83_17_89_47_73_42_80_69_94_98_61_52_67_85_80_47_60_59_47_56_81_33_22_18_95_84_36_33_36_59_79_25_59_1_77_56_76_15_59_87_67_92_26_83_67_24_82_79_33_97_30_40_97_54_64_18_80_5_94_82_43_8_52_35_11_78_67_97_32_80_37_100_29_48_51_13_58_62_66_93_7_66_22_56_97_21_35_63_25_30_73_6_91_66_44_63_90_65_38_82_20_9_40_9_50_3_45_19_27',
    //   // 'genes_58_80_62_9_69_12_46_22_88_26_84_14_76_13_81_63_60_68_30_58_4_26_0_70_72_9_50_53_96_69_48_56_63_93_78_58_39_33_31_41_38_14_99_79_22_18_74_73_68_29_59_83_22_26_99_0_82_57_25_40_72_33_98_33_0_48_14_99_0_25_93_30_77_88_72_19_56_37_13_26_18_44_1_30_88_11_41_2_100_32_73_0_53_24_8_21_68_28_79_14_44_5_100_40_47_93_40_55_95_0_40_25_26_46_41_74_69',
    //   // 'genes_57_85_11_91_97_88_92_22_92_9_45_47_72_51_56_38_39_68_9_61_61_38_80_43_87_49_53_55_71_8_45_41_91_19_7_42_27_59_13_63_84_1_57_56_8_26_83_86_63_72_56_86_88_35_2_0_81_47_68_39_41_62_62_40_63_30_48_78_73_47_96_66_73_19_73_63_67_96_71_97_23_17_57_3_85_10_9_72_98_52_94_1_51_21_53_95_27_87_39_76_62_5_35_18_90_88_38_52_21_0_62_5_49_46_79_29_34',
    //   // 'genes_100_83_37_90_70_60_94_21_92_67_81_47_84_9_56_40_96_98_0_58_27_42_65_52_60_30_62_48_76_33_5_97_91_50_72_48_35_57_34_97_47_1_17_42_77_18_81_78_21_54_77_87_46_24_30_79_85_100_35_39_73_13_4_37_8_7_86_48_57_47_74_59_55_75_52_18_14_69_38_100_76_5_88_8_36_87_73_40_12_23_76_52_56_21_27_100_25_57_18_76_4_79_44_79_5_93_76_1_17_2_33_17_51_62_60_81_57',
    //   // 'genes_98_28_15_66_16_53_94_70_37_29_86_10_32_10_82_0_39_21_85_40_54_69_81_58_42_71_61_44_27_29_5_98_92_8_28_50_35_29_26_37_84_60_14_56_13_8_78_84_21_29_28_83_64_17_47_0_43_98_74_30_96_96_48_99_83_30_86_75_16_42_93_58_55_82_33_69_2_77_64_18_1_37_21_6_4_90_49_88_88_74_57_89_54_49_11_56_89_87_16_72_4_29_30_20_47_97_74_82_84_2_25_22_51_62_98_38_68',
    //   // 'genes_61_65_100_58_62_79_81_77_29_55_89_54_72_87_82_65_65_67_89_39_45_15_96_1_75_78_30_9_63_44_2_34_85_63_100_66_35_43_50_9_89_70_71_67_61_9_87_96_36_73_78_86_60_38_16_0_84_43_27_36_75_67_14_36_20_25_4_100_4_5_52_72_13_16_59_52_18_29_38_10_54_5_9_1_43_92_13_37_98_100_78_53_53_2_32_100_63_100_33_50_21_10_39_30_95_45_86_94_5_92_62_65_64_60_74_23_11',
    //   // 'genes_61_60_72_10_40_79_25_63_11_13_85_12_65_42_81_56_50_26_31_95_76_39_100_66_56_65_25_98_81_33_55_78_26_88_43_33_40_47_28_98_88_0_88_66_43_0_87_96_10_23_59_61_67_74_16_6_45_78_27_41_46_18_80_18_1_5_6_32_9_26_52_16_54_76_63_56_29_43_67_94_77_35_57_3_61_83_66_40_94_75_53_89_46_21_33_20_24_17_72_50_22_51_94_35_49_28_86_75_9_1_71_22_51_64_64_13_19',
    //   // 'genes_40_60_69_7_61_12_21_22_23_26_95_87_62_29_84_63_48_68_32_50_36_66_0_43_85_9_61_31_8_99_46_46_86_93_81_58_89_48_31_40_29_68_14_59_22_18_87_73_68_73_59_87_21_24_90_60_85_57_20_71_72_21_98_38_0_25_67_75_4_29_95_24_77_32_76_0_56_89_71_14_71_34_16_9_40_32_8_36_6_1_97_24_9_24_12_100_22_95_73_14_0_98_43_55_93_95_46_78_9_3_69_90_11_65_55_74_58',
    //   // 'genes_57_39_51_67_67_87_19_67_92_25_81_52_32_10_85_59_52_98_0_50_3_41_0_42_72_76_50_25_0_18_98_31_69_48_96_15_82_11_79_70_59_43_57_82_42_4_22_98_64_73_54_87_39_17_19_1_44_54_13_41_79_67_9_33_0_32_52_46_78_41_19_97_55_51_55_54_49_36_66_86_86_2_18_9_78_11_73_94_46_5_97_6_60_49_10_91_58_36_80_95_66_50_35_59_88_98_23_16_29_4_42_24_93_62_84_32_11',
    //   // 'genes_41_39_72_11_40_79_93_68_92_28_83_10_70_42_85_56_95_54_31_95_62_41_79_47_56_9_21_27_81_69_22_78_80_88_42_71_82_80_31_30_56_1_88_59_24_0_35_77_64_67_59_57_67_61_18_99_89_57_27_41_97_18_64_33_83_25_86_30_55_93_16_81_40_82_63_25_72_66_11_14_33_62_57_48_85_57_8_36_12_19_63_81_46_21_75_63_24_30_15_22_62_4_39_35_50_89_86_52_88_42_71_47_40_51_29_68_62',
    //   // 'genes_9_60_20_2_62_60_84_24_85_27_73_56_62_25_83_39_5_98_29_94_27_66_14_44_72_14_21_48_22_67_46_49_92_10_36_73_77_10_73_87_56_35_66_67_43_9_30_96_91_31_44_65_64_68_90_90_67_88_27_43_50_96_77_8_1_27_78_32_56_29_93_12_25_15_72_57_15_42_48_78_81_43_10_6_61_62_80_24_7_0_70_89_6_43_27_90_19_62_73_14_87_22_43_60_50_93_43_55_9_3_96_20_66_61_79_13_85',
    //   // 'genes_100_50_55_56_71_79_54_94_37_22_83_97_62_42_82_40_24_75_84_75_85_98_73_17_59_72_64_20_95_95_11_80_65_88_12_25_18_78_31_97_69_19_88_77_34_2_5_86_9_26_78_82_19_19_13_74_40_47_31_37_75_56_96_87_2_33_11_75_55_76_10_97_43_23_51_56_5_43_92_21_1_41_6_9_19_83_9_19_22_50_95_1_24_21_9_2_56_100_17_39_1_98_36_50_0_27_46_69_16_66_10_19_61_64_98_33_52',
    //   // 'genes_58_11_15_65_64_37_52_75_97_72_16_28_43_70_17_3_55_18_39_13_54_71_69_45_59_65_41_21_90_65_0_29_2_36_25_9_18_35_29_40_62_18_17_79_67_99_63_91_10_72_82_37_76_19_90_21_40_62_69_57_85_58_75_44_80_35_83_7_52_44_93_32_70_56_57_100_14_81_69_100_25_7_51_6_63_6_73_83_10_100_80_17_0_76_28_21_91_96_21_17_66_60_25_96_47_93_78_55_83_4_45_34_42_41_58_6_71',
    //   // 'genes_100_78_33_0_100_40_92_100_44_26_86_47_62_36_19_5_36_8_68_38_37_63_96_56_22_60_60_55_90_67_5_37_43_48_39_59_52_78_97_97_65_58_14_61_79_12_30_99_82_72_54_85_84_57_12_62_63_100_18_87_4_8_78_26_73_30_9_100_54_49_90_26_42_95_57_18_68_41_36_100_100_55_23_8_15_90_37_93_12_79_77_75_100_96_8_98_91_67_26_24_24_0_18_39_38_17_20_52_33_9_24_17_29_70_13_79_64',
    //   // 'genes_9_8_22_60_40_83_56_22_97_18_49_3_31_94_56_36_59_74_32_61_80_21_19_47_91_49_53_48_85_31_93_46_89_10_44_23_77_30_13_30_29_80_0_75_30_8_59_86_25_75_15_82_65_20_27_79_81_45_68_39_6_60_96_44_100_30_48_82_3_8_100_53_73_82_98_25_56_96_69_100_88_5_71_3_85_51_8_7_4_36_77_40_57_26_27_41_27_53_39_45_63_18_86_41_48_21_49_52_71_66_62_61_66_62_14_33_34',
    //   // 'genes_59_39_51_60_70_79_4_52_40_37_85_49_4_73_85_56_22_94_32_96_3_41_0_38_72_76_29_28_9_69_55_50_69_48_96_15_82_17_78_9_50_1_96_60_44_9_67_98_10_73_59_84_50_29_16_0_82_60_13_41_75_67_85_72_23_78_87_78_13_26_16_97_55_43_67_25_32_38_65_91_100_62_62_4_78_79_75_16_12_23_78_6_5_22_79_21_58_36_80_3_66_50_94_36_93_30_9_62_50_8_84_21_84_45_87_32_11',
    //   'genes_28_48_28_77_69_83_77_40_29_88_53_58_15_51_3_14_23_27_12_5_45_43_85_20_83_53_92_7_41_82_84_77_100_57_90_60_22_44_0_79_28_48_28_77_69_83_77_40_29_88_53_58_15_51_3_14_23_27_12_5_45_43_85_20_83_53_92_7_41_82_84_77_100_57_90_60_22_44_0_79_28_48_28_77_69_83_77_40_29_88_53_58_15_51_3_14_23_27_12_5_45_43_85_20_83_53_92_7_41_82_84_77_57_100_90_60_22_44_0_79',
    //   'genes_47_70_22_83_72_63_95_0_2_57_31_96_12_82_5_21_96_22_67_24_44_40_87_61_17_90_88_68_41_91_78_90_100_63_6_62_22_0_62_22_47_70_22_83_72_63_95_0_2_57_31_96_12_82_5_21_96_22_67_24_44_40_87_61_17_90_88_68_41_91_78_90_100_63_6_62_22_0_62_22_47_70_22_83_72_63_95_0_2_57_31_96_12_82_5_21_96_22_67_24_44_40_87_61_17_90_88_68_41_91_78_90_63_100_6_62_22_0_62_22',
    //   'genes_6_31_40_19_99_80_64_15_26_57_53_66_3_95_7_28_9_25_38_66_35_82_25_52_42_71_14_43_82_26_95_84_100_61_61_86_72_4_11_35_6_31_40_19_99_80_64_15_26_57_53_66_3_95_7_28_9_25_38_66_35_82_25_52_42_71_14_43_82_26_95_84_100_61_61_86_72_4_11_35_6_31_40_19_99_80_64_15_26_57_53_66_3_95_7_28_9_25_38_66_35_82_25_52_42_71_14_43_82_26_95_84_61_100_61_86_72_4_11_35',
    //   'genes_17_47_97_78_91_1_72_0_37_12_61_50_10_46_6_18_4_77_47_35_32_81_90_100_92_42_58_12_12_87_83_33_100_33_5_97_12_39_0_6_17_47_97_78_91_1_72_0_37_12_61_50_10_46_6_18_4_77_47_35_32_81_90_100_92_42_58_12_12_87_83_33_100_33_5_97_12_39_0_6_17_47_97_78_91_1_72_0_37_12_61_50_10_46_6_18_4_77_47_35_32_81_90_100_92_42_58_12_12_87_83_33_33_100_5_97_12_39_0_6',
    //   'genes_29_29_35_96_80_79_74_47_80_11_48_34_13_91_4_22_0_26_11_66_45_53_71_59_42_32_57_70_52_90_81_40_100_73_61_12_60_0_0_30_29_29_35_96_80_79_74_47_80_11_48_34_13_91_4_22_0_26_11_66_45_53_71_59_42_32_57_70_52_90_81_40_100_73_61_12_60_0_0_30_29_29_35_96_80_79_74_47_80_11_48_34_13_91_4_22_0_26_11_66_45_53_71_59_42_32_57_70_52_90_81_40_73_100_61_12_60_0_0_30',
    //   'genes_45_19_50_82_83_84_96_20_28_65_34_9_11_43_4_63_18_26_67_50_35_77_67_7_45_35_17_43_88_52_43_13_100_82_76_91_11_39_60_75_45_19_50_82_83_84_96_20_28_65_34_9_11_43_4_63_18_26_67_50_35_77_67_7_45_35_17_43_88_52_43_13_100_82_76_91_11_39_60_75_45_19_50_82_83_84_96_20_28_65_34_9_11_43_4_63_18_26_67_50_35_77_67_7_45_35_17_43_88_52_43_13_82_100_76_91_11_39_60_75',
    //   'genes_27_33_69_62_76_2_76_2_36_52_85_41_4_48_3_52_57_26_37_65_98_77_68_61_8_42_26_69_18_90_78_39_100_62_8_20_57_5_44_15_27_33_69_62_76_2_76_2_36_52_85_41_4_48_3_52_57_26_37_65_98_77_68_61_8_42_26_69_18_90_78_39_100_62_8_20_57_5_44_15_27_33_69_62_76_2_76_2_36_52_85_41_4_48_3_52_57_26_37_65_98_77_68_61_8_42_26_69_18_90_78_39_62_100_8_20_57_5_44_15',
    //   'genes_36_44_24_33_86_0_100_13_32_7_67_0_12_82_22_3_89_22_78_91_34_53_8_61_11_39_26_41_38_93_37_46_100_57_5_40_61_37_0_11_36_44_24_33_86_0_100_13_32_7_67_0_12_82_22_3_89_22_78_91_34_53_8_61_11_39_26_41_38_93_37_46_100_57_5_40_61_37_0_11_36_44_24_33_86_0_100_13_32_7_67_0_12_82_22_3_89_22_78_91_34_53_8_61_11_39_26_41_38_93_37_46_57_100_5_40_61_37_0_11',
    //   'genes_36_44_24_33_86_0_100_13_32_7_67_0_12_82_22_3_89_22_78_91_34_53_8_61_11_39_26_41_38_93_37_46_100_57_5_40_61_37_0_11_36_44_24_33_86_0_100_13_32_7_67_0_12_82_22_3_89_22_78_91_34_53_8_61_11_39_26_41_38_93_37_46_100_57_5_40_61_37_0_11_36_44_24_33_86_0_100_13_32_7_67_0_12_82_22_3_89_22_78_91_34_53_8_61_11_39_26_41_38_93_37_46_57_100_5_40_61_37_0_11',
    //   'genes_17_47_97_78_91_1_72_0_37_12_61_50_10_46_6_18_4_77_47_35_32_81_90_100_92_42_58_12_12_87_83_33_100_33_5_97_12_39_0_6_17_47_97_78_91_1_72_0_37_12_61_50_10_46_6_18_4_77_47_35_32_81_90_100_92_42_58_12_12_87_83_33_100_33_5_97_12_39_0_6_17_47_97_78_91_1_72_0_37_12_61_50_10_46_6_18_4_77_47_35_32_81_90_100_92_42_58_12_12_87_83_33_33_100_5_97_12_39_0_6',
    // ];

    if (genes != null) {
      final geneString = genes!;

      for (var geneSetIndex = 0; geneSetIndex < numGeneCopies; geneSetIndex++) {
        final genes = Genes.fromGeneString(geneString, geneSetIndex);

        genePools.add(genes);
      }
    } else {
      final selectedGenes = randomChoice(
        [
          ...no_chat_genes,
        ],
      );

      for (var geneSetIndex = 0; geneSetIndex < numGeneCopies; geneSetIndex++) {
        genePools.add(selectedGenes);
      }
    }
  }

  void estimateKeeping(numPlayers, List<Set<String>> communities) {
    keepingStrength = {};
    final players = currentRound.info.playerPopularities.keys;
    for (final player in players) {
      // print('isKeeping for $player is ${isKeeping(player, players)}');
      // print('fearKeeping for $player is ${fearKeeping(players, communities, player)}');
      final keepingStrengthI =
          max(isKeeping(player, players), fearKeeping(players, communities, player));
      keepingStrength[player] = keepingStrengthI * currentRound.info.playerTokens;
    }
  }

  void computeUsefulQuantities() {
    // print('computing quantities...');
    final roundNum = currentRound.info.round;
    final influences = transposeMap(removeIntrinsic(currentRound.info.playerInfluences));
    if (roundNum > initialRound) {
      inflNegPrev = inflNeg.map(MapEntry.new);
    } else {
      inflNegPrev = clipNegMatrix(influences);
    }

    inflPos = clipMatrix(influences);
    inflNeg = clipNegMatrix(influences);

    inflPosSumCol = sumOverAxis0(inflPos);
    inflPosSumRow = sumOverAxis1(inflPos);

    final players = influences.keys;
    if (roundNum == initialRound) {
      sumInflPos = {
        for (final player1 in players) player1: {for (final player in players) player: 0.0}
      };
      attacksWithMe = {for (final player in players) player: 0.0};
      othersAttackOn = {for (final player in players) player: 0.0};

      inflictedDamageRatio = 1;
      badGuys = {for (final player in players) player: 0.0};
    } else {
      sumInflPos = addMatrices(sumInflPos, inflPos);

      const w = .2;

      for (final player in players) {
        var val = clipNegVector(influences.map((key, value) => MapEntry(
            key,
            value[player]! -
                (prevInfluence?[key]![player] ?? 0) *
                    (1.0 - gameParams.popularityFunctionParams.alpha)))).values.sum;
        final temp = (influences[myPlayerName]![player]! -
                (prevInfluence?[myPlayerName]![player]! ?? 0) *
                    (1.0 - gameParams.popularityFunctionParams.alpha)) *
            -1;
        val -= temp > 0 ? temp : 0;
        othersAttackOn[player] = othersAttackOn[player]! * w + (1 - w) * val;
        if (player != myPlayerName) {
          if ((prevAllocations?[player] ?? 0) < 0) {
            final amount = clipNegVector(prevInfluence?.map((key, value) => MapEntry(
                    key,
                    influences[key]![player]! -
                        value[player]! * (1.0 - gameParams.popularityFunctionParams.alpha))) ??
                {});
            attacksWithMe = subtractVectors(attacksWithMe, amount);
            if (expectedDefendFriendDamage != -99999) {
              final newRatio = amount.values.sum / expectedDefendFriendDamage;
              inflictedDamageRatio = .5 * inflictedDamageRatio + .5 * newRatio;
            }
          }
        }
      }
      badGuys.updateAll((key, value) => value * (1 - gameParams.popularityFunctionParams.alpha));
      final badGuysCopy = Map<String, double>.from(badGuys);
      final clippedPrev = clipNegMatrix(prevInfluence ?? {});
      final newSteals = inflNeg.map((key1, value) => MapEntry(
          key1,
          value.map((key2, value) => MapEntry(
              key2,
              value -
                  (clippedPrev[key1]?[key2] ?? 0) *
                      (1 - gameParams.popularityFunctionParams.alpha)))));
      for (final i in players) {
        for (final j in players) {
          if (newSteals[i]![j]! > 5.0) {
            if (badGuysCopy[j]! < 0.2) {
              badGuys[i] = badGuys[i]! + newSteals[i]![j]! / 1.0;
              if (badGuys[i]! > 1.0) {
                badGuys[i] = 1.0;
              }
            } else if (((inflNeg[j]!.values.sum) * 0.9) < (sumOverAxis0(inflNeg)[j]!)) {
              badGuys[j] = 0;
            }
          }
        }
      }
    }
  }

  Tuple2<List<Set<String>>, CommunityEvaluation> groupAnalysis() {
    final players = currentRound.info.playerPopularities.keys.toSet();

    if (currentRound.info.round == initialRound) {
      final aPos = computeAdjacency();
      final aNeg = computeNegAdjacency();

      final result = louvainCMethodPhase1(players.length, aPos, aNeg);
      final communitiesByIndex = result.first;
      final communities = convertComFromIdx(communitiesByIndex, players.toList());

      coalitionTarget = computeCoalitionTarget(communities);

      final elijo = randomSelections(players, currentRound.info.playerPopularities);

      // print('communities and elijo');
      // print(communities);
      // elijo.printCom();

      return Tuple2(communities, elijo);
    } else {
      final aPos = computeAdjacency();
      final aNeg = computeNegAdjacency();

      final result = louvainCMethodPhase1(currentRound.info.groupMembers.length, aPos, aNeg);
      final communitiesPh1 = result.first;
      final modularityPh1 = result.second;

      final result2 = louvainMethodPhase2(communitiesPh1, aPos, aNeg);
      final communitiesMega = result2.first;
      final modularity = result2.second;
      final communitiesByIndex =
          enumerateCommunity(modularityPh1, communitiesPh1, modularity, communitiesMega);

      // print('Communities after Phase2');
      // print(communitiesByIndex);

      final communities = convertComFromIdx(communitiesByIndex, players.toList());
      coalitionTarget = computeCoalitionTarget(communities);

      final elijo = envisionCommunities(
          aPos, aNeg, communitiesPh1, communitiesByIndex, communities, modularity);

      // print('communities and elijo');
      // print(communities);
      // elijo.printCom();

      return Tuple2(communities, elijo);
    }
  }

  Map<String, Map<String, double>> computeAdjacency() {
    final A = inflPos.map((key, value) => MapEntry(key, Map<String, double>.from(value)));
    for (final player in currentRound.info.playerPopularities.keys) {
      A[player]![player] = inflPos[player]![player]!;
      for (final otherPlayer in currentRound.info.playerPopularities.keys
          .toList()
          .sublist(currentRound.info.playerPopularities.keys.toList().indexOf(player) + 1)) {
        final theAve = (inflPos[player]![otherPlayer]! + inflPos[otherPlayer]![player]!) / 2;
        final theMin = min(inflPos[player]![otherPlayer]!, inflPos[otherPlayer]![player]!);
        A[player]![otherPlayer] = (theAve + theMin) / 2;
        A[otherPlayer]![player] = A[player]![otherPlayer]!;
      }
    }
    return A;
  }

  Map<String, Map<String, double>> computeNegAdjacency() {
    final A = inflNeg.map((key, value) => MapEntry(key, Map<String, double>.from(value)));
    for (final player in currentRound.info.playerPopularities.keys) {
      A[player]![player] = inflNeg[player]![player]!;
      for (final otherPlayer in currentRound.info.playerPopularities.keys
          .toList()
          .sublist(currentRound.info.playerPopularities.keys.toList().indexOf(player) + 1)) {
        // final theAve = (inflNeg[player]![otherPlayer]! + inflNeg[otherPlayer]![player]!) / 2;
        final theMax = max(inflNeg[player]![otherPlayer]!, inflNeg[otherPlayer]![player]!);
        A[player]![otherPlayer] = theMax; //(theAve + theMax) / 2;
        A[otherPlayer]![player] = A[player]![otherPlayer]!;
      }
    }

    return A;
  }

  // phase1 using number input
  Tuple2<List<Set<int>>, double> louvainCMethodPhase1(int numPlayers,
      Map<String, Map<String, double>> aPos, Map<String, Map<String, double>> aNeg) {
    final currentCommunities = List.generate(numPlayers, (index) => index);

    if (numPlayers == 0) {
      return const Tuple2([], 0);
    }

    final theGroups = List.generate(numPlayers, (index) => index).toSet();
    var comMatrix = Matrix.identity(numPlayers);
    final mPos = aPos.values
        .fold(0.toDouble(), (previousValue, element) => previousValue + element.values.sum);
    final kPos = sumOverAxis1(aPos);
    final mNeg = aNeg.values
        .fold(0.toDouble(), (previousValue, element) => previousValue + element.values.sum);
    final kNeg = sumOverAxis1(aNeg);
    var comCounts = Vector.filled(numPlayers, 1);
    var hayCambio = true;

    while (hayCambio) {
      hayCambio = false;
      for (var i = 0; i < numPlayers; i++) {
        var mxCom = currentCommunities[i];
        var bestDQ = 0.0;

        for (final j in theGroups) {
          if (currentCommunities[i] == j) {
            continue;
          }
          final dQPos = moveItoJ(numPlayers, comMatrix, mPos, mapToVector(kPos), mapToMatrix(aPos),
              i, j, currentCommunities[i]);

          final dQNeg = moveItoJ(numPlayers, comMatrix, mNeg, mapToVector(kNeg), mapToMatrix(aNeg),
              i, j, currentCommunities[i]);

          final dQ = alpha * dQPos - (1 - alpha) * dQNeg;
          if (dQ > bestDQ) {
            mxCom = j;
            bestDQ = dQ;
          }
        }
        if (bestDQ > 0) {
          comMatrix = setMatrixValue(comMatrix, currentCommunities[i], i, 0);
          comCounts = setVectorValue(
              comCounts, currentCommunities[i], comCounts[currentCommunities[i]] - 1);
          if (comCounts[currentCommunities[i]] <= 0) {
            theGroups.remove(currentCommunities[i]);
          }
          comMatrix = setMatrixValue(comMatrix, mxCom, i, 1);
          comCounts = setVectorValue(comCounts, mxCom, comCounts[mxCom] + 1);
          currentCommunities[i] = mxCom;
          hayCambio = true;
        }
      }
    }

    final communities = <Set<int>>[];
    for (var i = 0; i < numPlayers; i++) {
      if (comCounts[i] > 0) {
        final s = <int>{};
        for (var j = 0; j < numPlayers; j++) {
          if (comMatrix[i][j] == 1) {
            s.add(j);
          }
        }
        communities.add(s);
      }
    }

    var theModularity =
        alpha * computeModularity(numPlayers, currentCommunities, mapToMatrix(aPos));
    theModularity -=
        (1 - alpha) * computeModularity(numPlayers, currentCommunities, mapToMatrix(aNeg));

    // print('communities');
    // print(communities);
    // print('theModularity');
    // print(theModularity);

    return Tuple2(communities, theModularity);
  }

  Tuple2<List<Set<int>>, double> louvainMethodPhase2(List<Set<int>> communitiesPh1,
      Map<String, Map<String, double>> aPos, Map<String, Map<String, double>> aNeg) {
    final numCommunities = communitiesPh1.length;

    // Lump individuals into communities: compute B_pos and B_neg

    final bPos = {
      for (int i = 0; i < numCommunities; i++)
        i.toString(): {for (int j = 0; j < numCommunities; j++) j.toString(): 0.0}
    };
    final bNeg = {
      for (int i = 0; i < numCommunities; i++)
        i.toString(): {for (int j = 0; j < numCommunities; j++) j.toString(): 0.0}
    };

    final communities = convertComFromIdx(communitiesPh1, aPos.keys.toList());

    for (var i = 0; i < numCommunities; i++) {
      for (var j = 0; j < numCommunities; j++) {
        for (final k in communities[i]) {
          for (final m in communities[j]) {
            bPos[i.toString()]![j.toString()] = bPos[i.toString()]![j.toString()]! + aPos[k]![m]!;
            bNeg[i.toString()]![j.toString()] = bNeg[i.toString()]![j.toString()]! + aNeg[k]![m]!;
          }
        }
      }
    }
    // print('BValues');
    // print(bPos);
    // print(bNeg);

    return louvainCMethodPhase1(numCommunities, bPos, bNeg);
  }

  double moveItoJ(
      int numPlayers, Matrix comMatrix, double m, Vector K, Matrix A, int i, int comJ, int comI) {
    // first, what is the change in modularity from putting i into j's community
    var sigmaIn = 0.0;
    for (var k = 0; k < numPlayers; k++) {
      if (comMatrix[comJ][k] == 1) {
        sigmaIn += comMatrix[comJ].dot(A[k]);
      }
    }
    // print('sigmaIn');
    // print(sigmaIn);

    var sigmaTot = comMatrix[comJ].dot(K);
    var kIin = comMatrix[comJ].dot(A[i]);

    final twoM = 2 * m;
    if (twoM == 0) {
      return 0;
    }

    var a = (sigmaIn + 2 * kIin) / twoM;
    var b = (sigmaTot + K[i]) / twoM;
    var c = sigmaIn / twoM;
    var d = sigmaTot / twoM;
    var e = K[i] / twoM;
    final dqIn = (a - (b * b)) - (c - d * d - e * e);

    // second, what is the change in modularity from removing i from its community

    final com = comMatrix[comI].toList();
    com[i] = 0;
    sigmaIn = 0;
    for (var k = 0; k < numPlayers; k++) {
      if (com[k] == 1) {
        sigmaIn += Vector.fromList(com).dot(A[k]);
      }
    }

    sigmaTot = Vector.fromList(com).dot(K);

    kIin = Vector.fromList(com).dot(A[i]);

    a = (sigmaIn + 2 * kIin) / twoM;
    b = (sigmaTot + K[i]) / twoM;
    c = sigmaIn / twoM;
    d = sigmaTot / twoM;
    e = K[i] / twoM;
    final dQOut = (a - (b * b)) - (c - d * d - e * e);

    return dqIn - dQOut;
  }

  double computeModularity(int numPlayers, List currentCommunities, Matrix A) {
    final k = A.reduceRows((combine, vector) => combine + vector);
    final m = A.sum();

    if (m == 0) {
      return 0;
    }

    var Q = 0.0;

    for (var i = 0; i < numPlayers; i++) {
      for (var j = 0; j < numPlayers; j++) {
        Q += deltar(currentCommunities, i, j) * (A[i][j] - ((k[i] * k[j]) / (2 * m)));
      }
    }

    Q /= 2 * m;

    return Q;
  }

  int deltar(List currentCommunities, int i, int j) {
    if (currentCommunities[i] == currentCommunities[j]) {
      return 1;
    } else {
      return 0;
    }
  }

  double computeCoalitionTarget(List<Set<String>> communities) {
    // compute coalition_target
    if (activeGenes!.coalitionTarget < 80) {
      if (activeGenes!.coalitionTarget < 5) {
        return .05;
      } else {
        return activeGenes!.coalitionTarget / 100;
      }
    } else if (currentRound.info.round < 3) {
      return .51;
    } else {
      var inMx = false;
      var mxIdx = -1;

      final fuerza = <double>[];
      final popularities = currentRound.info.playerPopularities;
      final totPop = popularities.values.sum;
      for (final s in communities) {
        var tot = 0.0;
        for (final i in s) {
          tot += popularities[i]!;
        }

        fuerza.add(tot / totPop);
        if (mxIdx == -1) {
          mxIdx = 0;
        } else if (tot > fuerza[mxIdx]) {
          mxIdx = fuerza.length - 1;

          inMx = s.contains(myPlayerName);
        }
      }
      fuerza.sortReversed();

      if (inMx) {
        return min(fuerza[1] + .05, 55);
      } else {
        return min(fuerza[0] + .05, 55);
      }
    }
  }

  void updateIndebtedness(Map<String, int> transactionVec) {
    final popularities = currentRound.info.playerPopularities;
    final roundNum = currentRound.info.round;

    //       # update the tally of indebtedness
    final clippedTrans =
        clipVector(transactionVec.map((key, value) => MapEntry(key, value.toDouble())));
    tally.updateAll((key, value) => value - (clippedTrans[key]! * popularities[myPlayerName]!));

    tally[myPlayerName] = 0;

    var lmbda = 1 / roundNum; //+1;
    if (lmbda < gameParams.popularityFunctionParams.alpha) {
      lmbda = gameParams.popularityFunctionParams.alpha;
    }
    expectedReturn.updateAll((key, value) =>
        ((1 - lmbda) * expectedReturn[key]!) +
        (lmbda * (transactionVec[key]! * popularities[myPlayerName]!)));
    aveReturn = expectedReturn.values.sum / expectedReturn.length;
  }

  List<Set<String>> convertComFromIdx(List<Set<int>> communitiesByIndex, List<String> players) {
    final list = <Set<String>>[];

    for (final community in communitiesByIndex) {
      final members = <String>{};
      for (final memberIdx in community) {
        final memberName = players[memberIdx];
        members.add(memberName);
      }
      list.add(members);
    }

    return list;
  }

  List<Set<int>> convertComToIdx(List<Set<String>> communitiesByString, List<String> players) {
    final list = <Set<int>>[];

    for (final community in communitiesByString) {
      final members = <int>{};
      for (final memberName in community) {
        final memberIdx = players.indexOf(memberName);
        members.add(memberIdx);
      }
      list.add(members);
    }

    return list;
  }

  CommunityEvaluation randomSelections(Set<String> playerSet, Map<String, double> popularities) {
    final players = Set<String>.from(playerSet);
    players.remove(myPlayerName);

    final s = {myPlayerName};

    var pop = popularities[myPlayerName]!;
    final totalPop = popularities.values.sum;

    // coalitionTarget = self.genes["coalitionTarget"] / 100.0

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

    return CommunityEvaluation(
        s: s, centrality: 0, collectiveStrength: 0, familiarity: 0, modularity: 0, prosocial: 0);
  }

  List<Set<int>> enumerateCommunity(double modularityPh1, List<Set<int>> communitiesPh1,
      double modularity, List<Set<int>> communitiesMegaByIndex) {
    if (modularity > modularityPh1) {
      final communities = <Set<int>>[];
      for (final m in communitiesMegaByIndex) {
        communities.add(<int>{});
        for (final i in m) {
          // ignore: prefer_foreach
          for (final j in communitiesPh1[i]) {
            communities[communities.length - 1].add(j);
          }
        }
      }
      return communities;
    } else {
      return communitiesPh1;
    }
  }

  CommunityEvaluation envisionCommunities(
      Map<String, Map<String, double>> aPos,
      Map<String, Map<String, double>> aNeg,
      List<Set<int>> communitiesPh1,
      List<Set<int>> communitiesByIndex,
      List<Set<String>> communities,
      double modularity) {
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
    final determineCommunitiesResult =
        determineCommunities(communitiesByIndex, communities, sIdx, aPos, aNeg);
    communitiesPh1 = List.from(backup);

    var s = determineCommunitiesResult[0] as Set<String>;
    final m = determineCommunitiesResult[2] as double;

    final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
    s = removeMostlyDeadResult.first;
    potentialCommunities.add(CommunityEvaluation(
        s: s,
        modularity: m,
        centrality: getCentrality(s, currentRound.info.playerPopularities),
        collectiveStrength:
            getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
        familiarity: getFamiliarity(
            s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
        prosocial: getIngroupAntisocial(s)));

    // combine with any other group
    for (final i in communities) {
      if (i != s) {
        c = List<Set<String>>.from(communities).map(Set<String>.from).toList();
        c[sIdx] = c[sIdx].union(i);
        if (!alreadyIn(c[sIdx], potentialCommunities)) {
          c.remove(i);
          final determineCommunitiesResult = determineCommunities(
              convertComToIdx(c.cast(), currentRound.info.playerPopularities.keys.toList()),
              c.cast(),
              findCommunity(c.cast()),
              aPos,
              aNeg);
          var s = determineCommunitiesResult[0] as Set<String>;
          final m = determineCommunitiesResult[2] as double;
          final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
          s = removeMostlyDeadResult.first;

          potentialCommunities.add(CommunityEvaluation(
              s: s,
              modularity: m,
              centrality: getCentrality(s, currentRound.info.playerPopularities),
              collectiveStrength:
                  getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
              familiarity: getFamiliarity(
                  s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
              prosocial: getIngroupAntisocial(s)));
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
              aNeg);
          var s = determineCommunitiesResult[0] as Set<String>;
          final m = determineCommunitiesResult[2] as double;
          final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
          s = removeMostlyDeadResult.first;

          potentialCommunities.add(CommunityEvaluation(
              s: s,
              modularity: m,
              centrality: getCentrality(s, currentRound.info.playerPopularities),
              collectiveStrength:
                  getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
              familiarity: getFamiliarity(
                  s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
              prosocial: getIngroupAntisocial(s)));
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
              convertComToIdx(c.cast(), currentRound.info.playerPopularities.keys.toList()),
              c.cast(),
              findCommunity(c.cast()),
              aPos,
              aNeg);
          var s = determineCommunitiesResult[0] as Set<String>;
          final m = determineCommunitiesResult[2] as double;
          final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
          s = removeMostlyDeadResult.first;

          potentialCommunities.add(CommunityEvaluation(
              s: s,
              modularity: m,
              centrality: getCentrality(s, currentRound.info.playerPopularities),
              collectiveStrength:
                  getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
              familiarity: getFamiliarity(
                  s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
              prosocial: getIngroupAntisocial(s)));
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
              convertComToIdx(c.cast(), players.toList()), c.cast(), sIdx, aPos, aNeg);
          var s = determineCommunitiesResult[0] as Set<String>;
          final m = determineCommunitiesResult[2] as double;
          final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
          s = removeMostlyDeadResult.first;

          potentialCommunities.add(CommunityEvaluation(
              s: s,
              modularity: m,
              centrality: getCentrality(s, currentRound.info.playerPopularities),
              collectiveStrength:
                  getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
              familiarity: getFamiliarity(
                  s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
              prosocial: getIngroupAntisocial(s)));
        }
      }
    }

    final s2Idx = findCommunity(convertComFromIdx(communitiesPh1, players.toList()));
    final communitiesPh1ByPlayer = convertComFromIdx(communitiesPh1, players.toList());
    // if (sIdx != s2Idx) {
    if (!communities[sIdx].deepEquals(communitiesPh1ByPlayer[s2Idx], ignoreOrder: true)) {
      sIdx = s2Idx;
      // put in the original with combined other groups
      c = List<Set<String>>.from(communitiesPh1ByPlayer).map(Set<String>.from).toList();
      final determineCommunitiesResult = determineCommunities(
          convertComToIdx(c.cast(), currentRound.info.playerPopularities.keys.toList()),
          c.cast(),
          sIdx,
          aPos,
          aNeg);
      var s = determineCommunitiesResult[0] as Set<String>;
      final m = determineCommunitiesResult[2] as double;
      final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
      s = removeMostlyDeadResult.first;
      potentialCommunities.add(CommunityEvaluation(
          s: s,
          modularity: m,
          centrality: getCentrality(s, currentRound.info.playerPopularities),
          collectiveStrength:
              getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
          familiarity: getFamiliarity(
              s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
          prosocial: getIngroupAntisocial(s)));

      // print('potential communities');
      // for (final com in potentialCommunities) {
      //   com.printCom();
      // }

      // combine with any other group
      for (final i in communitiesPh1ByPlayer) {
        if (i != s) {
          c = List<Set<String>>.from(communitiesPh1ByPlayer).map(Set<String>.from).toList();
          c[sIdx] = c[sIdx].union(i);
          if (!alreadyIn(c[sIdx], potentialCommunities)) {
            c.remove(i);
            final determineCommunitiesResult = determineCommunities(
                convertComToIdx(c.cast(), currentRound.info.playerPopularities.keys.toList()),
                c.cast(),
                findCommunity(c.cast()),
                aPos,
                aNeg);
            var s = determineCommunitiesResult[0] as Set<String>;
            final m = determineCommunitiesResult[2] as double;
            final removeMostlyDeadResult =
                removeMostlyDead(s, currentRound.info.playerPopularities);
            s = removeMostlyDeadResult.first;

            potentialCommunities.add(CommunityEvaluation(
                s: s,
                modularity: m,
                centrality: getCentrality(s, currentRound.info.playerPopularities),
                collectiveStrength:
                    getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
                familiarity: getFamiliarity(
                    s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
                prosocial: getIngroupAntisocial(s)));
          }
        }
      }

      // move to a different group
      for (final i in communitiesPh1ByPlayer) {
        if (i != s) {
          c = List<Set<String>>.from(communitiesPh1ByPlayer).map(Set<String>.from).toList();
          c[communitiesPh1ByPlayer.indexOf(i)].add(myPlayerName);
          if (!alreadyIn(c[communitiesPh1ByPlayer.indexOf(i)], potentialCommunities)) {
            c[sIdx].remove(myPlayerName);
            final determineCommunitiesResult = determineCommunities(
                convertComToIdx(c.cast(), players.toList()),
                c.cast(),
                communitiesPh1ByPlayer.indexOf(i),
                aPos,
                aNeg);
            var s = determineCommunitiesResult[0] as Set<String>;
            final m = determineCommunitiesResult[2] as double;
            final removeMostlyDeadResult =
                removeMostlyDead(s, currentRound.info.playerPopularities);
            s = removeMostlyDeadResult.first;

            potentialCommunities.add(CommunityEvaluation(
                s: s,
                modularity: m,
                centrality: getCentrality(s, currentRound.info.playerPopularities),
                collectiveStrength:
                    getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
                familiarity: getFamiliarity(
                    s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
                prosocial: getIngroupAntisocial(s)));
          }
        }
      }

      // # add a member from another group
      for (final i in players) {
        if (!communitiesPh1ByPlayer[sIdx].contains(i)) {
          c = List<Set<String>>.from(communitiesPh1ByPlayer).map(Set<String>.from).toList();
          for (final s in c) {
            if (s.contains(i)) {
              s.remove(i);
              break;
            }
          }
          c[sIdx].add(i);
          if (!alreadyIn(c[sIdx], potentialCommunities)) {
            final determineCommunitiesResult = determineCommunities(
                convertComToIdx(c.cast(), currentRound.info.playerPopularities.keys.toList()),
                c.cast(),
                findCommunity(c.cast()),
                aPos,
                aNeg);
            var s = determineCommunitiesResult[0] as Set<String>;
            final m = determineCommunitiesResult[2] as double;
            final removeMostlyDeadResult =
                removeMostlyDead(s, currentRound.info.playerPopularities);
            s = removeMostlyDeadResult.first;

            potentialCommunities.add(CommunityEvaluation(
                s: s,
                modularity: m,
                centrality: getCentrality(s, currentRound.info.playerPopularities),
                collectiveStrength:
                    getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
                familiarity: getFamiliarity(
                    s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
                prosocial: getIngroupAntisocial(s)));
          }
        }
      }

      //subtract a member from the group (that isn't player_idx)
      for (final i in communitiesPh1ByPlayer[sIdx]) {
        if (i != myPlayerName) {
          c = List<Set<String>>.from(communitiesPh1ByPlayer).map(Set<String>.from).toList();
          c[sIdx].remove(i);
          if (!alreadyIn(c[sIdx], potentialCommunities)) {
            c.add(<String>{i});
            final determineCommunitiesResult = determineCommunities(
                convertComToIdx(c.cast(), players.toList()), c.cast(), sIdx, aPos, aNeg);
            var s = determineCommunitiesResult[0] as Set<String>;
            final m = determineCommunitiesResult[2] as double;
            final removeMostlyDeadResult =
                removeMostlyDead(s, currentRound.info.playerPopularities);
            s = removeMostlyDeadResult.first;

            potentialCommunities.add(CommunityEvaluation(
                s: s,
                modularity: m,
                centrality: getCentrality(s, currentRound.info.playerPopularities),
                collectiveStrength:
                    getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
                familiarity: getFamiliarity(
                    s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
                prosocial: getIngroupAntisocial(
                  s,
                )));
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

  int findCommunity(List<Set<String>> communities) {
    for (var i = 0; i < communities.length; i++) {
      if (communities[i].contains(myPlayerName)) {
        return i;
      }
    }
    // ignore: avoid_print
    print("Problem: Didn't find a community");

    return -1;
  }

  List determineCommunities(List<Set<int>> c, List<Set<String>> cString, int sIdx,
      Map<String, Map<String, double>> aPos, Map<String, Map<String, double>> aNeg) {
    final players = currentRound.info.playerPopularities.keys.toSet();

    final s = c[sIdx];
    final sString = cString[sIdx];
    c.removeAt(sIdx);

    final cMega = louvainMethodPhase2(c, aPos, aNeg).first;
    final cPrime = enumerateCommunity(0, c, 1, cMega);

    cPrime.add(s);

    final curComms = [for (int player = 0; player < players.length; player++) 0];
    for (var j = 0; j < cPrime.length; j++) {
      for (final i in cPrime[j]) {
        curComms[i] = j;
      }
    }

    final m = computeSignedModularity(currentRound.info.groupMembers.length, curComms, aPos, aNeg);

    return [sString, cPrime, m];
  }

  double computeSignedModularity(int numPlayers, List<int> curComms,
      Map<String, Map<String, double>> aPos, Map<String, Map<String, double>> aNeg) {
    var modu = alpha * computeModularity(numPlayers, curComms, mapToMatrix(aPos));
    modu -= (1 - alpha) * computeModularity(numPlayers, curComms, mapToMatrix(aNeg));

    return modu;
  }

  double computeModularity2(int numPlayers, List<Set<int>> communities, Matrix A) {
    final k = A.reduceRows((combine, vector) => combine + vector);
    final m = A.sum();

    if (m == 0) {
      return 0;
    }

    var Q = 0.0;

    for (var i = 0; i < numPlayers; i++) {
      for (var j = 0; j < numPlayers; j++) {
        Q += deltar2(communities, i, j) * (A[i][j] - ((k[i] * k[j]) / (2 * m)));
      }
    }

    Q /= 2 * m;

    return Q;
  }

  int deltar2(List<Set<int>> communities, int i, int j) {
    for (final s in communities) {
      if (s.contains(i) && s.contains(j)) {
        return 1;
      }
    }
    return 0;
  }

  Tuple2<Set<String>, Set<String>> removeMostlyDead(
      Set<String> s, Map<String, double> popularities) {
    final d = <String>{};
    final sN = <String>{};
    if (popularities[myPlayerName]! < 10) {
      return Tuple2(d, sN);
    }

    for (final i in s) {
      if (popularities[i]! < .1 * popularities[myPlayerName]!) {
        d.add(i);
      } else {
        sN.add(i);
      }
    }
    return Tuple2(sN, d);
  }

  double getCentrality(Set<String> s, Map<String, double> popularities) {
    var groupSum = 0.0;
    var mx = 0.0;
    var numGreater = 0;

    for (final i in s) {
      groupSum += popularities[i]!;
      if (popularities[i]! > mx) {
        mx = popularities[i]!;
      }
      if (popularities[i]! > popularities[myPlayerName]!) {
        numGreater += 1;
      }
    }

    if (groupSum > 0.0 && s.length > 1) {
      final aveSum = groupSum / s.length;
      final aveVal = popularities[myPlayerName]! / aveSum;
      final mxVal = popularities[myPlayerName]! / mx;
      final rankVal = 1 - (numGreater / (s.length - 1.0));

      return (aveVal + mxVal + rankVal) / 3.0;
    } else {
      return 1;
    }
  }

  double getCollectiveStrength(
      Map<String, double> popularities, Set<String> s, double curCommSize) {
    var proposed = 0.0;
    for (final i in s) {
      proposed += popularities[i]!;
    }

    proposed /= popularities.values.sum;

    double target;
    if (activeGenes!.coalitionTarget == 0) {
      target = .01;
    } else {
      target = activeGenes!.coalitionTarget / 100.0;
    }

    var base = 1.0 - ((target - curCommSize).abs() / target);
    if (base < .01) {
      base = .01;
    }
    base *= base;

    if ((proposed - curCommSize).abs() <= 0.03) {
      return base;
    } else if ((curCommSize - target).abs() < (proposed - target).abs()) {
      var nbase = 1.0 - ((target - proposed).abs() / target);
      if (nbase < .01) {
        nbase = .01;
      }
      return nbase * nbase;
    } else {
      final baseline = (1.0 + base) / 2.0;
      final w = (proposed - target).abs() / (curCommSize - target).abs();
      return ((1.0 - w) * 1.0) + (baseline * w);
    }
  }

  double getFamiliarity(
      Set<String> s, Set<String> players, Map<String, Map<String, double>> influences) {
    // print(inflPos);
    // print(influences);
    var mag = 0.0;
    for (final i in inflPos.keys) {
      // print('i $i playerName: $playerName adding ${inflPos[i]![playerName]!}');
      mag += inflPos[i]![myPlayerName]!;
    }
    if (mag > 0.0) {
      final randval = mag / players.length;
      var indLoyalty = 0.0;
      var scaler = 1.0;

      for (final i in s) {
        if (scaledBackNums[i]! < 0.05 && i != myPlayerName) {
          scaler *= (s.length - 1) / s.length;
        }
        if (influences[i]![myPlayerName]! * scaledBackNums[i]! > randval) {
          indLoyalty += influences[i]![myPlayerName]! * scaledBackNums[i]!;
        } else {
          indLoyalty += (influences[i]![myPlayerName]! * scaledBackNums[i]!) - randval;
        }
      }
      // print(scaler);
      // print(indLoyalty);
      // print(mag);
      final double familiarity = max(.01, scaler * (indLoyalty / mag));

      return familiarity;
    } else {
      return 1;
    }
  }

  double getIngroupAntisocial(Set<String> s) {
    var scl = 1.0;
    final piece = 1.0 / s.length;
    final remain = 1.0 - piece;
    for (final i in s) {
      if (i != myPlayerName) {
        var theInvestment = 0.0;
        var theReturn = 0.0;
        for (final j in s) {
          if (i != j) {
            theInvestment += sumInflPos[j]![i]!;
            theReturn += sumInflPos[i]![j]!;
          }
        }
        if (theInvestment > 0.0) {
          var val = theReturn / theInvestment;
          if (val > 1.0) {
            val = 1.0;
          }
          scl *= piece * val + remain;
        }
      }
    }
    return scl;
  }

  bool alreadyIn(Set s, List<CommunityEvaluation> potentialCommunities) {
    for (final c in potentialCommunities) {
      if (s.deepEquals(c.s, ignoreOrder: true)) {
        return true;
      }
    }
    return false;
  }

  double isKeeping(String otherPlayer, Iterable<String> players) {
    var meAmount = 0.0;
    var totalAmount = 0.0;
    for (final i in players) {
      if (currentRound.info.governmentRoundInfo.governmentPlayerNames?.contains(i) ?? false) {
        continue;
      }
      if (i != otherPlayer) {
        if (inflNeg[otherPlayer]![i]! > 0) {
          totalAmount += inflNeg[otherPlayer]![i]! / gameParams.popularityFunctionParams.cSteal;
          meAmount -= inflNeg[otherPlayer]![i]!;
        } else {
          totalAmount += inflPos[otherPlayer]![i]! / gameParams.popularityFunctionParams.cGive;
        }
      }
    }

    meAmount =
        (meAmount + inflPos[otherPlayer]![otherPlayer]! - inflNeg[otherPlayer]![otherPlayer]!) /
            gameParams.popularityFunctionParams.cKeep;

    totalAmount += meAmount;

    if (totalAmount > 0) {
      return meAmount / totalAmount;
    } else {
      return 1;
    }
  }

  double fearKeeping(Iterable<String> players, List<Set<String>> communities, String player) {
    final amigos = findCommunityVec(players, communities, player);
    final enemigos = (amigos - 1) * -1;

    var sm = 0.0;

    for (var i = 0; i < players.length; i++) {
      if (amigos[i] == 1) {
        sm = max(enemigos.dot(mapToMatrix(inflNeg).columns.toList()[i]), sm);
      }
    }

    var denom = 0.0;
    for (final i in inflPos.keys) {
      denom += inflPos[i]![player]!;
    }

    var fearTokens = 0.0;
    if (denom > 0) {
      fearTokens = sm / denom;
    }

    // assume everyone else has the same fear I do
    return min(1, fearTokens * (activeGenes!.fearDefense / 50));
  }

  Vector findCommunityVec(Iterable<String> players, List<Set<String>> communities, String player) {
    final myCommVec = List.generate(players.length, (index) => 0);
    for (final s in communities) {
      if (s.contains(player)) {
        for (final i in s) {
          myCommVec[players.toList().indexOf(i)] = 1;
        }
      }
    }
    return Vector.fromList(myCommVec);
  }

  int cuantoGuardo(Set<String> selectedCommunity) {
    final popularities = currentRound.info.playerPopularities;
    final players = popularities.keys.toList();

    if (popularities[myPlayerName]! <= gameParams.popularityFunctionParams.povertyLine) {
      return 0;
    }

    final numTokens = currentRound.info.playerTokens;

    if (currentRound.info.round == initialRound) {
      underAttack = (activeGenes!.initialDefense / 100) * popularities[myPlayerName]!;
    } else {
      final totalAttack = dotVectors(
          clipNegVector(currentRound.info.tokensReceived!
              .map((key, value) => MapEntry(key, value / numTokens))),
          popularities);

      final dUpdate = activeGenes!.defenseUpdate / 100;

      underAttack = (underAttack * (1 - dUpdate)) + (totalAttack * dUpdate);
    }

    final caution = activeGenes!.defensePropensity / 50;
    final selfDefenseTokens = min(numTokens,
        (((underAttack * caution) / popularities[myPlayerName]!) * numTokens + .5).toInt());

    // are there attacks on my friends by outsiders?  if so, consider keeping more tokens
    // this can be compared to the self.fear_keeping function
    final amigos = List.generate(players.length, (index) => 1);
    final enemigos = List.generate(players.length, (index) => 1);

    for (final player in players) {
      if (selectedCommunity.contains(player)) {
        enemigos[players.indexOf(player)] = 0;
      } else {
        amigos[players.indexOf(player)] = 0;
      }
    }

    var sm = 0.0;
    for (var i = 0; i < players.length; i++) {
      if (amigos[i] == 1) {
        sm = max(Vector.fromList(enemigos).dot(mapToMatrix(inflNeg).columns.toList()[i]), sm);
      }
    }

    var denom = 0.0;
    for (final i in inflPos.keys) {
      denom += inflPos[i]![myPlayerName]!;
    }

    var fearTokens = 0;
    if (denom > 0) {
      fearTokens = (sm / denom * numTokens + .5).toInt();
    }

    fearTokens = ((fearTokens * activeGenes!.fearDefense) / 50 + .5).toInt();

    final tokensGuardado = min(max(selfDefenseTokens, fearTokens), numTokens);
    final minGuardado = ((activeGenes!.minKeep / 100) * numTokens + .5).toInt();

    return max(tokensGuardado, minGuardado);
  }

  Tuple2<Map<String, int>, int> quienAtaco(
      int remainingToks, Set<String> selectedCommunity, List<Set<String>> communities) {
    final players = currentRound.info.playerPopularities.keys;
    final groupCat = groupCompare(communities);

    // print('remaining tokens: $remainingToks');

    final pillageChoice = pillageTheVillage(selectedCommunity, remainingToks, groupCat);
    // print('PILLAGERS : ${activeGenes!.pillagePriority}');
    // print(pillageChoice);

    final vengeanceChoice = takeVengeance(remainingToks);
    // print('VENGEANCE');
    // print(vengeanceChoice);
    final defendFriendChoice =
        defendFriend(remainingToks, selectedCommunity, communities, groupCat);

    final attackToks = {for (final player in players) player: 0};

    final attackPossibilities = <Tuple2<int, Tuple2<String?, int>>>[];
    if (pillageChoice.first != null) {
      attackPossibilities.add(Tuple2(activeGenes!.pillagePriority, pillageChoice));
    }
    if (vengeanceChoice.first != null) {
      attackPossibilities.add(Tuple2(activeGenes!.vengeancePriority, vengeanceChoice));
    }
    if (defendFriendChoice.first != null) {
      attackPossibilities.add(Tuple2(activeGenes!.defendFriendPriority, defendFriendChoice));
    }

    // decide which attack to do
    if (attackPossibilities.isNotEmpty) {
      attackPossibilities.sortReversed((a, b) => a.first.compareTo(b.first));
      if ((attackPossibilities[0].second.first != defendFriendChoice[0]) ||
          (attackPossibilities[0].second.second != defendFriendChoice[1])) {
        expectedDefendFriendDamage = -99999;
      }
      attackToks[attackPossibilities[0].second.first!] = attackPossibilities[0].second.second;
    } else {
      expectedDefendFriendDamage = -99999;
    }

    return Tuple2(attackToks, attackToks.values.sum);
  }

  Tuple2<String?, int> pillageTheVillage(
      Set<String> selectedCommunity, int remainingToks, Map<String, double> groupCat) {
    final popularities = currentRound.info.playerPopularities;
    final roundNum = currentRound.info.round;
    final numTokens = currentRound.info.playerTokens;
    final players = popularities.keys;
    final influences = transposeMap(removeIntrinsic(currentRound.info.playerInfluences));
    // print(
    //     '$playerName fury: ${activeGenes!.pillageFury}, priority: ${activeGenes!.pillagePriority},  delay: ${activeGenes!.pillageDelay / 10}');

    if ((popularities[myPlayerName]! <= 0) ||
        ((roundNum - 1) < (activeGenes!.pillageDelay / 10)) ||
        (activeGenes!.pillagePriority < 50)) {
      return const Tuple2(null, 0);
    }

    final numAttackTokens =
        min(remainingToks, (numTokens * (activeGenes!.pillageFury / 100) + .5).toInt());
    // print('$playerName num attack tokens: $numAttackTokens, fury: ${activeGenes!.pillageFury}');
    if (numAttackTokens <= 0) {
      return const Tuple2(null, 0);
    }

    var ratioPredictedSteals = 1.0;
    final predictedSteals = clipNegVector(attacksWithMe).values.sum;
    if (attacksWithMe[myPlayerName]! < 0) {
      ratioPredictedSteals = predictedSteals / (-attacksWithMe[myPlayerName]!);
    }

    if (roundNum < 5) {
      ratioPredictedSteals *= (activeGenes!.pillageCompanionship + 100) / 100;
    }

    final pillagePossibilities = <List>[];
    for (final player in players) {
      if ((currentRound.info.governmentRoundInfo.governmentPlayerNames?.contains(player) ??
              false) ||
          player == myPlayerName) {
        continue;
      }

      if (groupCat[player]! < 2 &&
          ((!selectedCommunity.contains(player)) || activeGenes!.pillageFriends >= 50)) {
        // playerName is not fearful of the group player is in and player_idx is willing to pillage friends (if i is a friend)
        var cantidad = numAttackTokens;
        var myWeight = popularities[myPlayerName]! * cantidad;
        var ratio = ratioPredictedSteals;
        var ratio2 = (myWeight +
                ((othersAttackOn[player]! / gameParams.popularityFunctionParams.alpha) *
                    numTokens)) /
            myWeight;
        if (ratio2 > ratioPredictedSteals) {
          ratio = ratio2;
        }
        var gain = myWeight - (popularities[player]! * keepingStrength[player]! / ratio);

        // print('myWeight: $myWeight');
        // print('popularities[$player]: ${popularities[player]}');
        // print('ratio: $ratio');
        // print('keeping strength $player: ${keepingStrength[player]}');

        while (((((gain * ratio) / numTokens) *
                    gameParams.popularityFunctionParams.alpha *
                    gameParams.popularityFunctionParams.cSteal) >
                popularities[player]! - gameParams.popularityFunctionParams.povertyLine) &&
            (cantidad > 0)) {
          cantidad -= 1;

          if (cantidad == 0) break;

          myWeight = popularities[myPlayerName]! * cantidad;
          ratio = ratioPredictedSteals;
          ratio2 = (myWeight +
                  ((othersAttackOn[player]! / gameParams.popularityFunctionParams.alpha) *
                      numTokens)) /
              myWeight;
          if (ratio2 > ratioPredictedSteals) {
            ratio = ratio2;
          }
          gain = myWeight - (popularities[player]! * keepingStrength[player]! / ratio);
        }

        if (cantidad == 0) continue;
        // if (keepingStrength[player]! < 30) print('gain: $gain');
        final stealROI = (gain * gameParams.popularityFunctionParams.cSteal) /
            (cantidad * popularities[myPlayerName]!);
        final damage = (gain / numTokens) *
            gameParams.popularityFunctionParams.cSteal *
            gameParams.popularityFunctionParams.alpha;

        // if (keepingStrength[player]! < 30) print('cantidad: $cantidad, stealROI: $stealROI');
        var immGainPerToken = stealROI *
            ((cantidad / numTokens) * popularities[myPlayerName]!) *
            gameParams.popularityFunctionParams.alpha;
        // if (keepingStrength[player]! < 30) print('immGainPerToken 1: $immGainPerToken');
        final friendPenalty = (1.0 - gameParams.popularityFunctionParams.beta) *
            (damage / popularities[player]!) *
            influences[player]![myPlayerName]!;
        immGainPerToken -= friendPenalty;
        // if (keepingStrength[player]! < 30) print('immGainPerToken 2: $immGainPerToken');
        // if (keepingStrength[player]! < 30) {
        //   print(
        //       'ROI: $ROI, numTokens: $numTokens, popularities[$playerName]: ${popularities[playerName]}');
        // }
        immGainPerToken -= ROI *
            ((cantidad / numTokens) * popularities[myPlayerName]!) *
            gameParams.popularityFunctionParams.alpha;
        // if (keepingStrength[player]! < 30) print('immGainPerToken 3: $immGainPerToken');

        immGainPerToken /= cantidad;
        // if (keepingStrength[player]! < 30) print('immGainPerToken 4: $immGainPerToken');

        //identify security threats
        final securityThreatAdvantage = immGainPerToken + damage / cantidad;
        final num myGrowth;
        final num theirGrowth;
        if (roundNum > initialRound + 3) {
          myGrowth = (currentRound.popularities[roundNum]![myPlayerName]! -
                  currentRound.popularities[roundNum - 4]![myPlayerName]!) /
              4.0;

          theirGrowth = (currentRound.popularities[roundNum]![player]! -
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
        // print('immGainPerToken: $immGainPerToken');
        if (immGainPerToken > margin) {
          pillagePossibilities.add([player, immGainPerToken, cantidad]);
        }
      }
    }

    // print('PILLAGE POSSIBILITIES');
    // print(pillagePossibilities);

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

  Tuple2<String?, int> takeVengeance(int tokensRemaining) {
    final popularities = currentRound.info.playerPopularities;
    final numTokens = currentRound.info.playerTokens;
    final players = popularities.keys;
    final influences = transposeMap(removeIntrinsic(currentRound.info.playerInfluences));
    if (popularities[myPlayerName]! <= 0 || activeGenes!.vengeancePriority < 50) {
      return const Tuple2(null, 0);
    }
    final multiplicador = activeGenes!.vengeanceMultiplier / 33.0;
    final vengenceMax = min(numTokens * activeGenes!.vengeanceMax / 100.0, tokensRemaining);

    var ratioPredictedSteals = 1.0;
    final predictedSteals = clipNegVector(attacksWithMe).values.sum;
    if (attacksWithMe[myPlayerName]! < 0) {
      ratioPredictedSteals = predictedSteals / (-attacksWithMe[myPlayerName]!);
    }

    final vengencePossibilities = <List>[];
    for (final player in players) {
      if ((currentRound.info.governmentRoundInfo.governmentPlayerNames?.contains(player) ??
              false) ||
          player == myPlayerName) {
        continue;
      }

      if (influences[player]![myPlayerName]! < 0 &&
          -influences[player]![myPlayerName]! > (.05 * popularities[myPlayerName]!) &&
          influences[player]![myPlayerName]! < influences[myPlayerName]![player]! &&
          popularities[player]! > .01) {
        final keepingStrengthW =
            keepingStrength[player]! * (popularities[player]! / popularities[myPlayerName]!);
        final theScore = numTokens *
            ((influences[player]![myPlayerName]! - influences[myPlayerName]![player]!) /
                (popularities[myPlayerName]! *
                    gameParams.popularityFunctionParams.cSteal *
                    gameParams.popularityFunctionParams.alpha));
        var cantidad =
            (min(-1.0 * (theScore - keepingStrengthW) * multiplicador, vengenceMax) + 0.5).toInt();

        if (cantidad <= 0) {
          continue;
        }

        var myWeight = popularities[myPlayerName]! * cantidad;
        var ratio = ratioPredictedSteals;
        var ratio2 = (myWeight +
                ((othersAttackOn[player]! / gameParams.popularityFunctionParams.alpha) *
                    numTokens)) /
            myWeight;
        if (ratio2 > ratioPredictedSteals) {
          ratio = ratio2;
        }
        var gain = myWeight - (popularities[player]! * keepingStrength[player]! / ratio);

        while (((((gain * ratio) / numTokens) *
                    gameParams.popularityFunctionParams.alpha *
                    gameParams.popularityFunctionParams.cSteal) >
                (popularities[player]! - gameParams.popularityFunctionParams.povertyLine)) &&
            (cantidad > 0)) {
          cantidad -= 1;
          if (cantidad == 0) break;

          myWeight = popularities[myPlayerName]! * cantidad;
          ratio = ratioPredictedSteals;
          ratio2 = (myWeight +
                  ((othersAttackOn[player]! / gameParams.popularityFunctionParams.alpha) *
                      numTokens)) /
              myWeight;
          if (ratio2 > ratioPredictedSteals) ratio = ratio2;
          gain = myWeight - (popularities[player]! * keepingStrength[player]! / ratio);
        }

        final stealROI = (gain * gameParams.popularityFunctionParams.cSteal) /
            (cantidad * popularities[myPlayerName]!);
        final damage = (gain / numTokens) *
            gameParams.popularityFunctionParams.cSteal *
            gameParams.popularityFunctionParams.alpha;

        var immGainPerToken = (stealROI - ROI) *
            ((cantidad / numTokens) * popularities[myPlayerName]!) *
            gameParams.popularityFunctionParams.alpha;
        immGainPerToken /= cantidad;

        final vengenceAdvantage = immGainPerToken + damage / cantidad;

        if (vengenceAdvantage > 0) {
          vengencePossibilities.add([player, vengenceAdvantage, cantidad]);
        }
      }
    }

    // random selection
    if (vengencePossibilities.isNotEmpty) {
      var mag = 0.0;
      for (final i in vengencePossibilities) {
        mag += i[1]! as double;
      }

      double num;
      if (USE_RANDOM) {
        num = Random().nextDouble();
      } else {
        num = .5;
      }

      var sumr = 0.0;

      for (final i in vengencePossibilities) {
        sumr += (i[1]! as double) / mag;
        if (num <= sumr) {
          return Tuple2(i[0] as String, i[2] as int);
        }
      }
    }
    return const Tuple2(null, 0);
  }

  Tuple2<String?, int> defendFriend(int remainingToks, Set<String> selectedCommunity,
      List<Set<String>> communities, Map<String, double> groupCat) {
    final popularities = currentRound.info.playerPopularities;
    final players = popularities.keys;
    final numTokens = currentRound.info.playerTokens;
    expectedDefendFriendDamage = -99999;
    // print('DEFEND FRIEND ($myPlayerName)');
    // print('defend friend priority: ${activeGenes!.defendFriendPriority}');
    // print(inflPosSumCol[myPlayerName]! <= 0);

    if ((popularities[myPlayerName]! <= 0) ||
        (inflPosSumCol[myPlayerName]! <= 0) ||
        (activeGenes!.defendFriendPriority < 50)) return const Tuple2(null, 0);

    final myCommVec = {for (final player in players) player: 0.0};
    for (final i in selectedCommunity) {
      if ((i == myPlayerName) | (meImporta[i]! > 0.1)) myCommVec[i] = 1.0;
    }

    final badMarks = {for (final player in players) player: 0.0};
    String? worstInd;
    var worstVal = 0.0;

    for (final player in players) {
      if ((currentRound.info.governmentRoundInfo.governmentPlayerNames?.contains(player) ??
              false) ||
          (player == myPlayerName) ||
          ((activeGenes!.attackGoodGuys < 50) && (badGuys[player]! < 0.2)) ||
          (groupCat[player] == 2)) {
        continue;
      }

      badMarks[player] = dotVectors(inflNeg[player]!, myCommVec);
      if (badMarks[player]! > 0) {
        final influenceOnPlayer = inflNeg.map((key, value) => MapEntry(key, value[player]!));
        badMarks[player] = badMarks[player]! - dotVectors(influenceOnPlayer, myCommVec);
      }

      badMarks[player] = adjustBadMarks(badMarks[player]!, player);

      if (popularities[player]! - gameParams.popularityFunctionParams.povertyLine <
          badMarks[player]!) {
        badMarks[player] = popularities[player]! - gameParams.popularityFunctionParams.povertyLine;
      }

      if (badMarks[player]! > worstVal && myCommVec[player] == 0) {
        worstInd = player;
        worstVal = badMarks[worstInd]!;
      }
    }

    if (worstInd != null) {
      // see how many tokens I should use on this attack
      var tokensNeeded = numTokens *
          badMarks[worstInd]! /
          (popularities[myPlayerName]! *
              gameParams.popularityFunctionParams.cSteal *
              gameParams.popularityFunctionParams.alpha);
      tokensNeeded +=
          keepingStrength[worstInd]! * (popularities[worstInd]! / popularities[myPlayerName]!);
      final multiplicador = activeGenes!.defendFriendMultiplier / 33.0;
      tokensNeeded *= multiplicador;
      final attackStrength = dotVectors(popularities, myCommVec) * inflictedDamageRatio;
      final myPart = tokensNeeded * (popularities[myPlayerName]! / attackStrength);
      final cantidad = min((myPart + 0.5).toInt(),
          min((((activeGenes!.defendFriendMax / 100.0) * numTokens) + 0.5).toInt(), remainingToks));

      if ((cantidad >= (myPart - 1)) && (tokensNeeded > 0)) {
        // see if the attack is a good idea
        final gain = (tokensNeeded * popularities[myPlayerName]!) -
            (popularities[worstInd]! * keepingStrength[worstInd]!);
        final stealROI = (gain * gameParams.popularityFunctionParams.cSteal) /
            (tokensNeeded * popularities[myPlayerName]!);
        final immGainPerToken = (stealROI - ROI) *
            popularities[myPlayerName]! *
            gameParams.popularityFunctionParams.alpha;
        double vengenceAdvantage;
        if (groupCat[worstInd] == 0 && activeGenes!.groupAware >= 50) {
          // defend more violently against weaker groups (if group aware)
          vengenceAdvantage = immGainPerToken +
              2.0 * ((gain * gameParams.popularityFunctionParams.alpha) / tokensNeeded);
        } else {
          vengenceAdvantage =
              immGainPerToken + (gain * gameParams.popularityFunctionParams.alpha) / tokensNeeded;
        }

        if (vengenceAdvantage > 0.0) {
          expectedDefendFriendDamage = gain *
              gameParams.popularityFunctionParams.alpha *
              gameParams.popularityFunctionParams.cSteal /
              numTokens;
          return Tuple2(worstInd, cantidad);
        }
      }
    }
    return const Tuple2(null, 0);
  }

  Tuple2<Map<String, int>, int> groupGivings(
      int numGivingTokens, CommunityEvaluation selectedCommunity, Map<String, int> attackAlloc) {
    final players = currentRound.info.playerPopularities.keys;

    if (numGivingTokens <= 0) {
      final groupAlloc = {for (final player in players) player: 0};
      return Tuple2(groupAlloc, 0);
    }

    // allocate tokens based on homophily

    final homophilyVec = getHomophilyVec();
    final homophilyAllocateResult =
        homophilyAllocateTokens(numGivingTokens, homophilyVec, attackAlloc);
    final homophilyAlloc = homophilyAllocateResult.first;
    final numTokensH = homophilyAllocateResult.second;

    // print(numTokensH);
    // print(numGivingTokens);

    final groupAllocateResult =
        groupAllocateTokens(numGivingTokens - numTokensH, selectedCommunity, attackAlloc);
    var groupAlloc = groupAllocateResult.first;
    final numTokensG = groupAllocateResult.second;

    // for now, just keep tokens that you don't know what to do with
    groupAlloc[myPlayerName] =
        groupAlloc[myPlayerName]! + (numGivingTokens - (numTokensH + numTokensG));

    // print('groupAlloc');
    // print(groupAlloc);
    if (currentRound.info.playerPopularities[myPlayerName]! > 0.0001) {
      groupAlloc =
          dialBack(currentRound.info.playerTokens, addIntVectors(homophilyAlloc, groupAlloc)).first;
    }

    return Tuple2(groupAlloc, groupAlloc.values.sum);
  }

  Map<String, int> getHomophilyVec() {
    final players = currentRound.info.playerPopularities.keys;
    final homophilyVec = {for (final player in players) player: 0};
    for (final player in players) {
      if (player != myPlayerName) {
        // print(genes!.homophily);
        if (activeGenes!.homophily > 66 && getVisualHomophilySimilarity(player) > 0) {
          homophilyVec[player] = 1;
        } else if (activeGenes!.homophily < 34 && getVisualHomophilySimilarity(player) == 0) {
          homophilyVec[player] = 1;
        } else {
          homophilyVec[player] = 0;
        }
      }
    }

    // print(homophilyVec);
    return homophilyVec;
  }

  int getVisualHomophilySimilarity(String player) {
    final diff = (visualTraits[myPlayerName]! - visualTraits[player]!).abs();
    if (diff < 20) {
      return 1;
    } else {
      return 0;
    }
  }

  Tuple2<Map<String, int>, int> homophilyAllocateTokens(
      int numGivingTokens, Map<String, int> homophilyVec, Map<String, int> attackAlloc) {
    final toks = {for (final player in currentRound.info.playerPopularities.keys) player: 0};
    return Tuple2(toks, 0);
  }

  // Tuple2<Map<String, int>, int> groupAllocateTokens(
  //     int numTokens, CommunityEvaluation theCommunity, Map<String, int> attackAlloc) {
  //   final players = currentRound.info.playerPopularities.keys;
  //   final roundNum = currentRound.info.round;
  //   final sModified = Set<String>.from(theCommunity.s);

  //   // print(numTokens);
  //   // theCommunity.printCom();
  //   // print(attackAlloc);
  //   // for (final player in players) {
  //   //   if (attackAlloc[player]! != 0) {
  //   //     if (sModified.contains(player)) {
  //   //       sModified.remove(player);
  //   //     }
  //   //   }
  //   // }

  //   final toks = {for (final player in players) player: 0};

  //   var numAllocated = numTokens;
  //   if (roundNum == initialRound) {
  //     if (sModified.length == 1) {
  //       toks[myPlayerName] = numTokens;
  //     } else {
  //       for (var i = 0; i < numTokens; i++) {
  //         String sel;
  //         if (USE_RANDOM) {
  //           sel = randomChoice(sModified);
  //         } else {
  //           sel = sModified.toList().first;
  //         }
  //         while (sel == myPlayerName) {
  //           if (USE_RANDOM) {
  //             sel = randomChoice(sModified);
  //           } else {
  //             sel = sModified.toList()[1];
  //           }
  //         }
  //         toks[sel] = toks[sel]! + 1;
  //       }
  //     }
  //   } else {
  //     var commSize = sModified.length;
  //     if (commSize <= 1) {
  //       toks[myPlayerName] = numTokens;
  //     } else {
  //       final profile = <Tuple2<String, double>>[];
  //       var mag = 0.0;
  //       for (final i in sModified) {
  //         if (i != myPlayerName) {
  //           final sb = scaledBackNums[i]!;
  //           if (sb > 0) {
  //             final val = (inflPos[i]![myPlayerName]! + 0.01) * sb;
  //             profile.add(Tuple2(i, val));
  //             mag += val;
  //           }
  //         }
  //       }

  //       if (mag > 0) {
  //         profile.sortReversed((a, b) => a.second.compareTo(b.second));
  //         var remainingToks = numTokens;
  //         commSize = profile.length;
  //         final fixedUsage = ((activeGenes!.fixedUsage / 100.0) * numTokens) / commSize;

  //         final flexTokens = numTokens - (fixedUsage * commSize);
  //         for (var i = 0; i < commSize; i++) {
  //           // print(  'fixedUsage: $fixedUsage, flexTokens: $flexTokens, profile: ${profile[i].second} mag: $mag, remainingToks: $remainingToks');
  //           final giveEm = (fixedUsage + flexTokens * (profile[i].second / mag) + 0.5).toInt();
  //           if (remainingToks >= giveEm) {
  //             toks[profile[i].first] = toks[profile[i].first]! + giveEm;
  //             remainingToks -= giveEm;
  //           } else {
  //             toks[profile[i].first] = toks[profile[i].first]! + remainingToks;
  //             remainingToks = 0;
  //           }
  //         }

  //         while (remainingToks > 0) {
  //           for (var i = 0; i < commSize; i++) {
  //             toks[profile[i].first] = toks[profile[i].first]! + 1;
  //             remainingToks -= 1;

  //             if (remainingToks == 0) break;
  //           }
  //         }
  //       } else {
  //         numAllocated = 0;
  //       }
  //     }
  //   }

  //   return Tuple2(toks, numAllocated);
  // }

  Tuple2<Map<String, int>, int> groupAllocateTokens(
      int numTokens, CommunityEvaluation theCommunity, Map<String, int> attackAlloc) {
    final players = currentRound.info.playerPopularities.keys;
    final roundNum = currentRound.info.round;
    final sModified = Set<String>.from(theCommunity.s);

    sModified.remove(myPlayerName); // I added this in

    for (final player in players) {
      if (attackAlloc[player]! != 0) {
        if (sModified.contains(player)) {
          sModified.remove(player);
        }
      }
    }

    final toks = {for (final player in players) player: 0};

    var numAllocated = numTokens;
    if (roundNum == initialRound) {
      if (sModified.isEmpty) {
        // updated this
        toks[myPlayerName] = numTokens;
      } else {
        for (var i = 0; i < numTokens; i++) {
          var sel = '';
          if (USE_RANDOM) {
            sel = randomChoice(sModified);
          } else {
            sel = sModified.toList().first;
          }
          // removing this because it isn't necessary
          // while (sel == myPlayerName) {
          //   if (USE_RANDOM) {
          //     sel = randomChoice(sModified);
          //   } else {
          //     sel = sModified.toList()[1];
          //   }
          // }

          if (sel == '') {
            print('we have a problem in groupTokenAlloc');
          }

          toks[sel] = toks[sel]! + 1;
        }
      }
    } else {
      var commSize = sModified.length + 1;
      if (commSize <= 1) {
        toks[myPlayerName] = numTokens;
      } else {
        final profile = <Tuple2<String, double>>[];
        var mag = 0.0;
        // for (final i in sModified) {
        for (final i in players) {
          if (sModified.contains(i)) {
            // if (i != myPlayerName) {
            final sb = scaledBackNums[i];
            if (sb! > 0) {
              final val = (inflPos[i]![myPlayerName]! + 0.01) * sb;
              profile.add(Tuple2(i, val));
              mag += val;
            }
          }
        }
        // if (myPlayerIndex == printIndex) {
        //   print('profile: $profile');
        //   print('scaledBackNums: $scaledBackNums');
        //   print('******************** $mag');
        // }

        if (mag > 0) {
          profile.sortReversed((a, b) => a.second.compareTo(b.second));
          // if (myPlayerIndex == printIndex) {
          //   print('profile: $profile');
          // }
          var remainingToks = numTokens;
          commSize = profile.length;
          final fixedUsage = ((activeGenes!.fixedUsage / 100.0) * numTokens) / commSize;

          final flexTokens = numTokens - (fixedUsage * commSize);

          // if (myPlayerIndex == printIndex) {
          //   print('        fixedUsage: $fixedUsage');
          //   print('        flexTokens: $flexTokens');
          //   print('        mag: $mag');
          // }
          for (var i = 0; i < commSize; i++) {
            // print(  'fixedUsage: $fixedUsage, flexTokens: $flexTokens, profile: ${profile[i].second} mag: $mag, remainingToks: $remainingToks');
            final giveEm = (fixedUsage + flexTokens * (profile[i].second / mag) + 0.5).toInt();
            if (remainingToks >= giveEm) {
              // if (myPlayerIndex == printIndex) {
              //   print('      enough (${profile[i].first}): $giveEm');
              // }
              toks[profile[i].first] = toks[profile[i].first]! + giveEm;
              remainingToks -= giveEm;
            } else {
              toks[profile[i].first] = toks[profile[i].first]! + remainingToks;
              remainingToks = 0;
            }
          }

          while (remainingToks > 0) {
            for (var i = 0; i < commSize; i++) {
              toks[profile[i].first] = toks[profile[i].first]! + 1;
              remainingToks -= 1;

              if (remainingToks == 0) break;
            }
          }
        } else {
          numAllocated = 0;
        }
      }
    }

    return Tuple2(toks, numAllocated);
  }

  Tuple2<Map<String, int>, int> dialBack(int playerTokens, Map<String, int> giveAlloc) {
    final popularities = currentRound.info.playerPopularities;
    final players = currentRound.info.playerPopularities.keys;
    final numTokens = currentRound.info.playerTokens;
    final percLmt = (activeGenes!.limitingGive) / 100.0;
    // print(giveAlloc);
    var shave = 0;
    for (final player in players) {
      if (player == myPlayerName) {
        continue;
      }
      if (giveAlloc[player]! > 0) {
        final lmt =
            (((popularities[player]! / popularities[myPlayerName]!) * numTokens * percLmt) + 0.5)
                .toInt();
        if (lmt < giveAlloc[player]!) {
          shave += giveAlloc[player]! - lmt;
          giveAlloc[player] = lmt;
        }
      }
    }
    // print(shave);

    giveAlloc[myPlayerName] = giveAlloc[myPlayerName]! + shave;

    return Tuple2(giveAlloc, shave);
  }

  /// Determines relationship (in size) of player_idx's group with that of the other groups
  /// -1: in same group
  /// 0: (no competition) player_idx's group is much bigger
  /// 1: (rivals) player_idx's group if somewhat the same size and one of us is in the most powerful group
  /// 2: (fear) player_idx's group is much smaller

  Map<String, double> groupCompare(List<Set<String>> communities) {
    final popularities = currentRound.info.playerPopularities;
    final players = popularities.keys;

    final groupCat = {for (final player in players) player: 0.0};
    if (activeGenes!.groupAware < 50) {
      //     # don't do anything different -- player is not group aware
      return groupCat;
    }

    final commIdx = {for (final player in players) player: 0};
    final poders = {for (var c = 0; c < players.length; c++) c: 0.0};

    for (var c = 0; c < communities.length; c++) {
      for (final i in communities[c]) {
        commIdx[i] = c;
        poders[c] = poders[c]! + popularities[i]!;
      }
    }

    final mxPoder = poders.values.max;

    const scaler = 1.3; //this is arbitary for now
    for (final player in players) {
      if (commIdx[player] == commIdx[myPlayerName]) {
        groupCat[player] = -1;
      } else if (poders[commIdx[player]]! > (scaler * poders[commIdx[myPlayerName]]!)) {
        groupCat[player] = 2;
      } else if (((scaler * poders[commIdx[player]]!) > poders[commIdx[myPlayerName]]!) &&
          ((poders[commIdx[player]] == mxPoder) || (poders[commIdx[myPlayerName]] == mxPoder))) {
        groupCat[player] = 1;
      } else if (popularities[player]! > popularities[myPlayerName]!) {
        groupCat[player] = 1;
      }
    }

    return groupCat;
  }

  double adjustBadMarks(double currentMarks, String player) {
    return currentMarks;
  }
}

class CommunityEvaluation {
  CommunityEvaluation({
    required this.s,
    required this.modularity,
    required this.centrality,
    required this.collectiveStrength,
    required this.familiarity,
    required this.prosocial,
  });

  final Set<String> s;
  double modularity;
  final double centrality;
  final double collectiveStrength;
  final double familiarity;
  final double prosocial;
  var score = 0.0;
  var target = 0.0;

  double computeScore(Genes genes) {
    // this.target = target;

    score = 1.0;
    score = getModularityVal(genes);
    score *= getCentralityVal(genes);
    // final csWeight = pow(0.5, (collectiveStrength - target).abs() / 0.125);
    score *= getCollectiveStrengthVal(genes);
    score *= getFamiliarityVal(genes);
    score *= getProsocialVal(genes);

    // if (USE_RANDOM) {
    //   score += Random().nextDouble() / 10.0;
    // } else {
    //   score += modularity / 10.0;
    // }
    return score;
  }

  double getModularityVal(Genes genes) {
    return ((100 - genes.wModularity) + (genes.wModularity * modularity)) / 100.0;
  }

  double getCentralityVal(Genes genes) {
    return ((100 - genes.wCentrality) + (genes.wCentrality * centrality)) / 100.0;
  }

  double getCollectiveStrengthVal(Genes genes) {
    return ((100 - genes.wCollectiveStrength) + (genes.wCollectiveStrength * collectiveStrength)) /
        100.0;
  }

  double getFamiliarityVal(Genes genes) {
    return ((100 - genes.wFamiliarity) + (genes.wFamiliarity * familiarity)) / 100.0;
  }

  double getProsocialVal(Genes genes) {
    return ((100 - genes.wProsocial) + (genes.wProsocial * prosocial)) / 100.0;
  }

  double getModularityDifference(CommunityEvaluation? otherCommunity, Genes genes) {
    return getModularityVal(genes) - (otherCommunity?.getModularityVal(genes) ?? 0);
  }

  double getCentralityDifference(CommunityEvaluation? otherCommunity, Genes genes) {
    return getCentralityVal(genes) - (otherCommunity?.getCentralityVal(genes) ?? 0);
  }

  double getCollectiveStrengthDifference(CommunityEvaluation? otherCommunity, Genes genes) {
    return getCollectiveStrengthVal(genes) - (otherCommunity?.getCollectiveStrengthVal(genes) ?? 0);
  }

  double getFamiliarityDifference(CommunityEvaluation? otherCommunity, Genes genes) {
    return getFamiliarityVal(genes) - (otherCommunity?.getFamiliarityVal(genes) ?? 0);
  }

  double getProsocialDifference(CommunityEvaluation? otherCommunity, Genes genes) {
    return getProsocialVal(genes) - (otherCommunity?.getProsocialVal(genes) ?? 0);
  }

  // double getDifference(CommunityEvaluation? otherCommunity, Genes genes) {
  //   var score1 = 1.0;
  //   score1 = _getModularityVal(genes);
  //   score1 *= _getCollectiveStrengthVal(genes);
  //   score1 *= _getProsocialVal(genes);

  //   print(
  //       'mod: ${_getModularityVal(genes)} col: ${_getCollectiveStrengthVal(genes)} pro: ${_getProsocialVal(genes)}');

  //   var score2 = 1.0;
  //   if (otherCommunity != null) {
  //     score2 = otherCommunity._getModularityVal(genes);
  //     score2 *= otherCommunity._getCollectiveStrengthVal(genes);
  //     score2 *= otherCommunity._getProsocialVal(genes);
  //   } else {
  //     score2 = 0;
  //   }

  //   print(
  //       'mod: ${otherCommunity!._getModularityVal(genes)} col: ${otherCommunity._getCollectiveStrengthVal(genes)} pro: ${otherCommunity._getProsocialVal(genes)}');
  //   return score1 - score2;
  // }

  void printCom() {
    // # print(str(self.s) + ": " + str(self.modularity))
    print(''); // ignore: avoid_print
    print('set: $s'); // ignore: avoid_print
    print('   modularity: $modularity'); // ignore: avoid_print
    print('   centrality: $centrality'); // ignore: avoid_print
    final csWeight = pow(0.5, ((collectiveStrength - target) / .125).abs()); // ignore: avoid_print
    print(// ignore: avoid_print
        '   collective_strength: $collectiveStrength ($target; $csWeight)');
    print('   familiarity: $familiarity'); // ignore: avoid_print
    print('   prosocial: $prosocial'); // ignore: avoid_print
    print('   score: $score'); // ignore: avoid_print
    print(''); // ignore: avoid_print
  }
}

// class GeneAgentTest {
//   GeneAgentTest({this.numGeneCopies = 3, this.genes});
//   final String? genes;
//   List<Genes> genePools = [];
//   Genes? activeGenes;
//   final initialRound = 1;
//   late double alpha;
//   late Map<String, double> tally;
//   late Map<String, double> unpaidDebt;
//   late Map<String, double> punishableDebt;
//   late Map<String, double> expectedReturn;
//   late double aveReturn;
//   late Map<String, double> scaledBackNums;
//   late double receivedValue;
//   late double investedValue;
//   late double ROI;
//   Map<String, double>? prevPopularities;
//   Map<String, double>? prevAllocations;
//   Map<String, Map<String, double>>? prevInfluence;
//   late double coalitionTarget;
//   late Map<String, double> keepingStrength;
//   late double underAttack;
//   late Map<String, double> visualTraits;
//   final int numGeneCopies;

//   late Map<String, Map<String, double>> inflNeg;
//   late Map<String, Map<String, double>> inflPos;
//   late Map<String, Map<String, double>> inflNegPrev;
//   late Map<String, double> inflPosSumCol;
//   late Map<String, double> inflPosSumRow;
//   late Map<String, Map<String, double>> sumInflPos;
//   late Map<String, double> attacksWithMe;
//   late Map<String, double> othersAttackOn;
//   late Map<String, double> badGuys;
//   late double inflictedDamageRatio;
//   double expectedDefendFriendDamage = 99999;
//   late Map<String, double> meImporta;
//   List<Set<String>> observedCommunities = [];

//   int TEMP_TRUST_RATE = 10;
//   int TEMP_DISTRUST_RATE = 30;
//   int TEMP_STARTING_TRUST = 100;
//   int TEMP_W_CHAT_AGREEMENT = 75;
//   int TEMP_W_TRUST = 75;
//   int TEMP_W_ACCUSATIONS = 100;

//   //Remove these after testing
//   late RoundState currentRound;
//   late GameParams gameParams;
//   late String myPlayerName;

//   Future<void> nextRound(
//       RoundState testCurrentRound, String testPlayerName, GameParams testGameParams) async {
//     currentRound = testCurrentRound;
//     myPlayerName = testPlayerName;
//     gameParams = testGameParams;
//     // print(
//     //     'agent.play_round(0, ${currentRound.info.round}, np.array([${currentRound.info.tokensReceived?.values}]), np.array([${currentRound.info.playerPopularities.values}]), np.array([${mapToMatrix(transposeMap(removeIntrinsic(currentRound.info.playerInfluences)))}]), {})');

//     final roundNum = currentRound.info.round;
//     final numPlayers = currentRound.info.groupMembers.length;
//     final numTokens = currentRound.info.playerTokens;
//     visualTraits = {for (final player in currentRound.info.playerPopularities.keys) player: 0};

//     if (activeGenes == null) initializeGenes();

//     if (roundNum == initialRound) {
//       initVars();
//     } else {
//       updateVars();
//     }

//     alpha = activeGenes!.alpha / 100;

//     computeUsefulQuantities();

//     // group analysis and choice
//     final groupAnalysisRes = groupAnalysis();
//     final communities = groupAnalysisRes.first;
//     final selectedCommunity = groupAnalysisRes.second;
//     // print('community');
//     // selectedCommunity.printCom();

//     // figure out how many tokens to keep
//     estimateKeeping(numPlayers, communities);

//     final bool safetyFirst;
//     if (activeGenes!.safetyFirst < 50) {
//       safetyFirst = false;
//     } else {
//       safetyFirst = true;
//     }

//     var guardoToks = cuantoGuardo(selectedCommunity.s);
//     // print('guardo');
//     // print(guardoToks);

//     // determine who to attack (if any)
//     final Map<String, int> attackAlloc;
//     final int numAttackToks;
//     var remainingToks = 0;
//     if (roundNum > initialRound) {
//       remainingToks = currentRound.info.playerTokens;
//       if (safetyFirst) {
//         remainingToks -= guardoToks;
//       }

//       final atacoResult = quienAtaco(remainingToks, selectedCommunity.s, communities);
//       // print('atacoResult');
//       // print(atacoResult);
//       attackAlloc = atacoResult.first;
//       numAttackToks = atacoResult.second;
//     } else {
//       attackAlloc = {for (final player in currentRound.info.playerPopularities.keys) player: 0};
//       remainingToks = numTokens - guardoToks;
//       numAttackToks = 0;
//     }

//     // if (!safetyFirst) {
//     //   guardoToks = min(guardoToks, numTokens - numAttackToks);
//     // }

//     // figure out who to give tokens to

//     final groupsAlloc =
//         groupGivings(numTokens - numAttackToks - guardoToks, selectedCommunity, attackAlloc).first;
//     // print('groupsAlloc');
//     // print(groupsAlloc);
//     // print('attackAlloc');
//     // print(attackAlloc);

//     // update some variables
//     final transactionVec = subtractIntVectors(groupsAlloc, attackAlloc);
//     guardoToks =
//         numTokens - transactionVec.map((key, value) => MapEntry(key, value.abs())).values.sum;

//     transactionVec[myPlayerName] = transactionVec[myPlayerName]! + guardoToks;

//     prevPopularities = currentRound.info.playerPopularities;
//     prevAllocations = transactionVec.map((key, value) => MapEntry(key, value.toDouble()));
//     prevInfluence = transposeMap(removeIntrinsic(currentRound.info.playerInfluences));

//     updateIndebtedness(transactionVec);
//     // print('updated indebtedness');

//     if (transactionVec[myPlayerName]! < 0) {
//       // ignore: avoid_print
//       print('$myPlayerName is stealing from self!!!');
//     }

//     print(
//         '$myPlayerName transactions: ${transactionVec.map((key, value) => MapEntry(key, value.toDouble()))}');

//     // await submitTransactions(transactionVec.map((key, value) => MapEntry(key, value.toDouble())));
//   }
// // HELPER FUNCTIONS FOR PYTHON TRANSLATION

//   Map<String, double> clipVector(Map<String, double> map) {
//     return map.map((key, value) => MapEntry(key, max(0, value)));
//   }

//   Map<String, Map<String, double>> clipMatrix(Map<String, Map<String, double>> map) {
//     return map.map((key, value) => MapEntry(key, clipVector(value)));
//   }

//   Map<String, double> clipNegVector(Map<String, double> map) {
//     return map.map((key, value) => MapEntry(key, value < 0 ? value.abs() : 0));
//   }

//   Map<String, Map<String, double>> clipNegMatrix(Map<String, Map<String, double>> map) {
//     return map.map((key, value) =>
//         MapEntry(key, value.map((key, value) => MapEntry(key, value < 0 ? value.abs() : 0))));
//   }

//   Map<String, double> sumOverAxis0(Map<String, Map<String, double>> map) {
//     final newMap = {
//       for (final player in map.keys) player: 0.0,
//     };

//     map.forEach((key1, value) {
//       value.forEach((key2, infl) {
//         newMap.update(key2, (value) => value + infl);
//       });
//     });

//     return newMap;
//   }

//   Map<String, double> sumOverAxis1(Map<String, Map<String, double>> map) {
//     return map.map((key, value) => MapEntry(key, value.values.sum));
//   }

//   Map<String, Map<String, double>> removeIntrinsic(Map<String, Map<String, double>> map) {
//     final result = map.map((key, value) => MapEntry(key, Map<String, double>.from(value)));
//     result.updateAll((key, value) => value..remove('__intrinsic__'));
//     return result;
//   }

//   Map<String, Map<String, double>> transposeMap(Map<String, Map<String, double>> map) {
//     final result = map.map((key, value) => MapEntry(key, Map<String, double>.from(value)));
//     map.forEach((i, row) {
//       row.forEach((j, value) {
//         result[j]![i] = value;
//       });
//     });

//     return result;
//   }

//   Map<String, Map<String, double>> addMatrices(
//       Map<String, Map<String, double>> a, Map<String, Map<String, double>> b) {
//     final result = a.map((rowKey, value) => MapEntry(
//         rowKey, value.map((colKey, value) => MapEntry(colKey, value + b[rowKey]![colKey]!))));
//     return result;
//   }

//   Map<String, int> addIntVectors(Map<String, int> a, Map<String, int> b) {
//     return a.map((key, value) => MapEntry(key, value + b[key]!));
//   }

//   Map<String, int> subtractIntVectors(Map<String, int> a, Map<String, int> b) {
//     return a.map((key, value) => MapEntry(key, value - b[key]!));
//   }

//   Map<String, double> subtractVectors(Map<String, double> a, Map<String, double> b) {
//     return a.map((key, value) => MapEntry(key, value - b[key]!));
//   }

//   double dotVectors(Map<String, double> a, Map<String, double> b) {
//     final newMap = a.map((key, value) => MapEntry(key, value * b[key]!));
//     return newMap.values.sum;
//   }

//   Matrix setMatrixValue(Matrix matrix, int i, int j, double value) {
//     final asLists = matrix.toList();
//     final listOfLists = <List<double>>[];
//     for (final list in asLists) {
//       listOfLists.add(list.toList());
//     }
//     listOfLists[i][j] = value;
//     return Matrix.fromList(listOfLists);
//   }

//   Vector setVectorValue(Vector vector, int i, double value) {
//     final list = vector.toList();
//     list[i] = value;
//     return Vector.fromList(list);
//   }

//   Matrix mapToMatrix(Map<String, Map<String, double>>? map) {
//     final matrix = Matrix.fromList(
//         map?.values.toList().map((e) => e.values.toList()).toList() ?? [],
//         dtype: DType.float64);
//     return matrix;
//   }

//   Vector mapToVector(Map<String, double>? map) {
//     final matrix = Vector.fromList(map?.values.toList() ?? [], dtype: DType.float64);
//     return matrix;
//   }

//   // END HELPER FUNCTIONS

//   void initVars() {
//     activeGenes = genePools[determineGenePool()];
//     final players = currentRound.info.groupMembers;
//     tally = {for (final player in players) player: 0.0};
//     unpaidDebt = {for (final player in players) player: 0.0};
//     punishableDebt = {for (final player in players) player: 0.0};
//     expectedReturn = {for (final player in players) player: 0.0};
//     aveReturn = 0.0;
//     scaledBackNums = {for (final player in players) player: 1.0};
//     receivedValue = 0.0;
//     investedValue = 0.0;
//     ROI = gameParams.popularityFunctionParams.cKeep;
//   }

//   void updateVars() {
//     activeGenes = genePools[determineGenePool()];

//     tally.updateAll((key, value) =>
//         value +
//         (currentRound.info.tokensReceived?[key] ?? 0) *
//             currentRound.info.playerTokens *
//             (prevPopularities?[key] ?? 0));
//     tally[myPlayerName] = 0;

//     punishableDebt.updateAll((key, value) => 0);

//     final players = currentRound.info.groupMembers;
//     for (final player in players) {
//       if (tally[player]! < 0 && unpaidDebt[player]! < 0) {
//         punishableDebt[player] = -max(unpaidDebt[player]!, tally[player]!);
//       }
//     }

//     unpaidDebt.updateAll((key, value) => tally[key]!);

//     for (final player in players) {
//       if (player != myPlayerName) {
//         scaledBackNums[player] = scaleBack(player);
//       }
//     }

//     //   self.printT(player_idx, " scale_back: " + str(self.scaled_back_nums))

//     receivedValue *= 1 - gameParams.popularityFunctionParams.alpha;
//     final received = currentRound.info.tokensReceived;
//     for (final player in players) {
//       if (player == myPlayerName) {
//         receivedValue += (received?[player] ?? 0) *
//             (prevPopularities?[player] ?? 0) *
//             gameParams.popularityFunctionParams.cKeep;
//       } else if ((received?[player] ?? 0) < 0) {
//         receivedValue += received![player]! *
//             (prevPopularities?[player] ?? 0) *
//             gameParams.popularityFunctionParams.cSteal;
//       } else if ((received?[player] ?? 0) > 0) {
//         receivedValue += received![player]! *
//             (prevPopularities?[player] ?? 0) *
//             gameParams.popularityFunctionParams.cGive;
//       }
//     }
//     investedValue *= 1 - gameParams.popularityFunctionParams.alpha;
//     investedValue +=
//         clipVector(prevAllocations ?? {}).values.sum * (prevPopularities?[myPlayerName] ?? 0);
//     if (investedValue > 0) {
//       ROI = receivedValue / investedValue;
//     } else {
//       ROI = gameParams.popularityFunctionParams.cKeep;
//     }
//     if (ROI < gameParams.popularityFunctionParams.cKeep) {
//       ROI = gameParams.popularityFunctionParams.cKeep;
//     }
//   }

//   int determineGenePool() {
//     if (numGeneCopies == 1) return 0;
//     if (numGeneCopies != 3) {
//       throw Exception('gene agent not configured for $numGeneCopies copies');
//     }

//     // compute the mean
//     final m = currentRound.info.playerPopularities.values.sum / currentRound.info.numPlayers;
//     // print(currentRound.info.playerPopularities);
//     final ratio = currentRound.info.playerPopularities[myPlayerName]! / m;

//     if (ratio > 1.25) {
//       return 2;
//     } else if (ratio < 0.75) {
//       return 0;
//     } else {
//       return 1;
//     }
//   }

//   double scaleBack(
//     String quien,
//   ) {
//     if (currentRound.info.governmentRoundInfo.governmentPlayerNames?.contains(quien) ?? false) {
//       //for now, don't scale back payments to the gov'ment
//       return 1;
//     }

//     // consider scaling back if the other person is in debt to me
//     // print('DEBT');
//     // print(punishableDebt);
//     if (punishableDebt[quien]! > 0) {
//       final debtLimit = activeGenes!.otherishDebtLimits / 25;
//       if (debtLimit > 0) {
//         final denom = max(expectedReturn[quien]!, aveReturn) * debtLimit;
//         if (denom == 0) {
//           return 0;
//         } else {
//           final perc = 1.0 - (punishableDebt[quien]! / denom);
//           if (perc > 0) {
//             return perc;
//           } else {
//             return 0;
//           }
//         }
//       }
//     }

//     return 1;
//   }

//   void initializeGenes() {
//     // const assassinGenes =
//     //     'genes_50_50_1_25_0_50_100_0_0_0_0_100_50_50_50_50_0_100_2_80_0_50_0_100_100_100_100_100_90_100_100_0_0_50_50_1_25_0_50_100_0_0_0_0_100_50_50_50_50_0_100_2_80_0_50_0_100_100_100_100_100_90_100_100_0_0_50_50_1_25_0_50_100_0_0_0_0_100_50_50_50_50_0_100_2_80_0_50_0_100_100_100_100_100_90_100_100_0_0';
//     const bullyGenes =
//         'genes_50_20_50_50_25_50_50_100_50_80_50_70_20_20_50_50_0_50_30_60_20_0_0_50_100_100_100_100_100_90_0_100_0_50_20_50_50_25_50_50_100_50_80_50_70_20_20_50_50_0_50_30_60_20_0_0_50_100_100_100_100_100_90_0_100_0_50_20_50_50_25_50_50_100_50_80_50_70_20_20_50_50_0_50_30_60_20_0_0_50_100_100_100_100_100_90_0_100_0';

//     final topAgents = [
//       //Old chat-less genes
//       // 'gene_97_36_57_60_87_45_37_14_5_9_11_54_57_57_38_82_98_15_21_69_21_20_100_0_18_6_66_8_46_69_64_67_68_10_30_100_75_75_100_58_98_79_21_56_46_18_89_85_74_40_76_12_54_54_39_50_93_11_26_59_85_91_44_76_4_72_29_6_97_30_18_11_10_30_100_75_75_100_51_82_24_16_84_28_44_13_33_14_66_32_1_73_7_88_23_46_23_13_1_69_65_18_6_1_96_88_52_33_75_2_10_10_30_100_75_75_100',
//       // 'gene_59_67_93_11_44_46_49_98_44_66_7_66_54_38_57_98_95_13_88_31_75_13_71_57_83_13_46_18_7_90_53_71_74_10_30_100_75_75_100_98_56_72_16_45_43_46_89_33_14_38_75_8_46_4_34_38_46_94_5_62_69_67_39_92_10_100_88_7_77_46_15_29_10_30_100_75_75_100_99_50_29_34_43_4_13_74_49_18_22_73_14_83_3_42_72_63_87_22_80_51_15_93_6_40_76_89_42_95_54_25_91_10_30_100_75_75_100',
//       // 'gene_54_38_10_22_56_53_75_1_50_47_36_45_44_30_48_70_52_6_71_69_54_13_66_85_83_13_75_48_50_17_65_96_75_10_30_100_75_75_100_34_34_62_16_25_15_80_100_62_19_94_90_25_61_23_29_55_72_49_8_16_72_34_75_100_10_44_29_5_48_71_23_81_10_30_100_75_75_100_65_26_77_20_42_6_56_33_52_7_31_48_6_90_8_97_67_82_89_21_3_54_79_5_30_65_82_41_65_17_72_88_26_10_30_100_75_75_100',
//       // 'gene_72_68_95_29_46_67_75_21_49_23_79_56_54_8_74_31_67_11_12_47_18_70_68_86_77_65_51_18_0_91_19_66_45_10_30_100_75_75_100_100_34_15_16_64_59_16_64_46_77_50_20_36_45_20_64_65_50_46_4_35_84_5_75_72_10_69_84_5_93_28_30_33_10_30_100_75_75_100_36_18_12_56_38_3_41_21_33_30_64_27_11_83_11_40_16_96_92_22_52_0_16_78_11_65_80_10_44_86_51_40_10_10_30_100_75_75_100',
//       // 'gene_39_49_26_58_39_62_39_21_62_47_81_47_54_40_59_78_84_12_82_33_54_24_68_1_77_8_81_55_0_67_71_10_75_10_30_100_75_75_100_93_96_86_18_48_4_66_15_17_0_3_82_27_57_18_56_80_52_79_59_58_7_76_41_82_8_30_26_88_40_83_26_57_10_30_100_75_75_100_6_96_46_90_89_6_35_74_49_79_64_32_23_1_3_97_17_87_40_31_5_7_77_79_31_37_58_31_64_37_71_96_54_10_30_100_75_75_100',
//       // 'gene_92_23_41_63_60_55_37_4_49_16_40_36_56_49_50_59_72_23_84_54_41_56_54_25_43_11_88_76_2_53_70_97_22_10_30_100_75_75_100_0_96_72_22_64_54_46_3_100_14_17_9_17_52_54_19_69_25_87_35_18_11_8_68_76_22_75_95_8_83_74_92_11_10_30_100_75_75_100_17_30_25_17_44_37_81_21_71_72_71_49_18_72_3_13_19_46_85_29_2_63_87_81_59_21_80_32_39_28_72_2_92_10_30_100_75_75_100',
//       // 'gene_54_56_42_29_52_59_88_40_100_50_81_77_50_57_44_100_17_73_91_27_17_24_3_7_89_14_47_8_59_87_30_48_46_10_30_100_75_75_100_2_49_82_22_51_27_69_11_31_74_38_10_13_94_3_34_80_52_94_8_48_35_52_37_72_12_69_6_90_35_76_22_19_10_30_100_75_75_100_71_20_17_48_68_0_38_74_47_91_41_30_11_82_46_61_75_36_74_22_100_5_12_66_46_41_78_48_70_75_71_5_16_10_30_100_75_75_100',
//       // 'gene_50_25_54_11_69_0_55_51_50_51_11_53_99_38_54_84_17_75_91_27_28_66_69_67_77_59_51_65_64_59_54_100_70_10_30_100_75_75_100_100_22_12_16_49_22_86_89_96_18_46_24_26_94_54_59_59_100_94_17_62_1_87_5_77_67_91_54_35_69_76_29_19_10_30_100_75_75_100_34_0_73_30_37_45_83_23_54_13_66_86_15_23_9_67_11_31_83_28_50_0_90_81_66_40_39_41_63_41_71_0_68_10_30_100_75_75_100',
//       // 'gene_50_36_57_67_42_53_30_38_87_47_57_40_46_57_59_41_100_13_67_28_65_9_100_31_98_18_53_49_0_53_53_67_45_10_30_100_75_75_100_36_96_41_40_60_95_34_54_78_78_100_77_24_65_36_24_55_47_94_56_62_13_24_48_9_10_59_3_27_49_40_64_30_10_30_100_75_75_100_37_0_14_29_42_7_44_17_23_65_26_73_28_43_17_42_34_42_66_20_11_72_84_0_26_52_73_80_33_44_69_9_18_10_30_100_75_75_100',
//       // 'gene_56_32_93_18_61_12_52_90_44_48_87_95_54_11_44_20_99_7_94_67_33_38_94_93_13_95_44_53_61_90_88_85_43_10_30_100_75_75_100_25_47_57_58_41_62_17_47_79_32_46_91_32_71_92_61_100_36_96_25_55_9_19_45_3_32_26_1_28_86_68_23_96_10_30_100_75_75_100_72_17_14_68_43_50_80_74_24_69_90_35_29_82_7_100_69_38_75_7_96_56_83_42_76_37_98_0_64_76_75_39_7_10_30_100_75_75_100',
//       // 'gene_70_31_24_64_48_75_39_75_100_80_79_37_83_13_18_83_80_75_36_5_21_53_79_14_62_25_79_29_31_23_85_13_39_10_30_100_75_75_100_87_55_42_52_36_87_56_38_67_59_70_57_71_91_52_61_71_93_0_28_8_5_0_77_44_67_4_10_3_52_46_40_66_10_30_100_75_75_100_30_63_97_9_84_30_6_51_96_98_62_10_5_79_61_91_58_58_49_38_49_20_46_32_3_68_38_35_98_66_69_94_81_10_30_100_75_75_100',
//       // 'gene_67_88_8_2_59_86_41_48_97_92_100_19_36_47_99_63_17_73_43_64_60_4_76_72_32_24_86_57_51_36_85_97_17_10_30_100_75_75_100_29_8_38_28_41_90_45_16_60_41_28_76_7_88_37_76_35_62_20_37_5_78_96_84_21_42_8_6_49_30_23_42_59_10_30_100_75_75_100_88_45_44_1_70_20_43_52_100_74_14_11_9_81_40_53_56_93_88_82_93_42_47_16_76_4_36_47_26_26_68_61_92_10_30_100_75_75_100',
//       // 'gene_74_30_47_39_28_89_77_74_13_97_71_15_85_100_0_2_12_3_78_8_12_7_73_24_90_10_11_60_62_54_85_66_64_10_30_100_75_75_100_70_75_63_52_93_7_20_71_53_91_12_85_55_3_27_88_75_70_0_68_8_74_63_56_44_90_16_0_58_86_78_49_70_10_30_100_75_75_100_82_33_72_78_71_5_42_40_93_75_58_11_7_58_61_89_32_20_49_72_100_20_85_59_74_37_79_36_2_54_81_30_42_10_30_100_75_75_100',
//       // 'gene_72_38_32_54_72_64_66_2_99_14_91_85_83_93_11_58_95_6_78_27_70_13_37_9_55_53_4_79_9_40_69_48_59_10_30_100_75_75_100_42_7_65_52_38_49_68_11_53_55_58_7_26_51_81_88_50_20_4_0_38_2_0_26_13_40_26_0_45_87_61_36_70_10_30_100_75_75_100_85_73_12_58_70_19_0_81_5_96_67_70_8_61_1_38_43_20_18_3_91_41_30_29_62_65_7_78_2_100_73_9_41_10_30_100_75_75_100',
//       // 'gene_72_97_46_57_26_90_9_97_95_57_75_85_90_93_39_54_95_3_78_51_65_53_75_8_90_38_4_79_54_33_42_48_59_10_30_100_75_75_100_87_70_0_48_28_76_70_39_71_97_58_7_39_99_78_60_50_73_0_5_13_2_24_80_52_16_4_1_2_53_89_53_39_10_30_100_75_75_100_82_85_39_59_80_17_30_38_5_98_5_11_6_61_0_90_32_20_47_51_95_20_44_83_3_49_5_36_6_100_81_9_72_10_30_100_75_75_100',
//       // 'gene_70_49_47_5_54_17_67_72_100_88_60_85_85_100_24_58_5_10_29_21_71_75_37_96_28_46_79_63_50_54_16_42_20_10_30_100_75_75_100_73_73_95_36_47_81_16_26_64_90_61_28_15_5_16_83_59_56_42_87_12_49_0_55_45_47_66_5_65_76_54_42_34_10_30_100_75_75_100_69_70_48_0_75_0_8_30_96_74_82_24_9_41_0_86_80_21_49_72_32_15_53_61_23_0_38_36_7_57_93_98_23_10_30_100_75_75_100',
//       // 'gene_68_92_7_10_49_42_67_78_5_9_100_43_90_100_15_24_4_8_24_49_64_53_71_68_10_5_63_60_9_50_85_58_35_10_30_100_75_75_100_31_68_0_46_96_76_62_14_78_89_45_13_39_73_98_83_48_87_69_11_25_20_81_64_3_42_28_0_3_53_50_49_89_10_30_100_75_75_100_57_45_13_11_83_96_27_62_5_75_35_8_24_100_36_39_60_49_44_51_50_20_34_53_61_55_95_9_6_45_51_100_32_10_30_100_75_75_100',
//       // 'gene_61_30_0_59_27_94_80_1_100_32_15_15_41_2_18_25_7_41_36_12_65_7_19_94_55_38_40_57_26_50_74_55_67_10_30_100_75_75_100_26_74_1_60_40_74_49_88_5_97_64_37_34_84_75_56_46_22_4_89_9_78_0_39_58_42_28_10_0_68_26_53_100_10_30_100_75_75_100_34_53_35_82_81_25_13_43_48_83_86_12_7_9_61_37_32_53_55_68_53_73_44_32_20_4_25_35_94_73_96_68_25_10_30_100_75_75_100',
//       // 'gene_43_100_38_20_77_27_67_76_99_13_14_81_35_93_6_45_95_11_44_93_87_71_47_8_91_76_48_54_61_53_46_49_35_10_30_100_75_75_100_36_81_22_57_43_52_42_69_49_94_28_77_17_80_24_69_54_12_2_10_34_52_0_39_13_93_0_12_49_40_19_43_36_10_30_100_75_75_100_79_92_17_59_33_96_6_63_5_56_89_21_10_48_0_33_35_18_49_33_63_2_32_52_38_38_5_100_5_69_74_58_8_10_30_100_75_75_100',
//       // 'gene_62_42_27_67_53_72_23_72_92_80_7_70_39_98_20_67_5_43_57_24_61_43_37_42_20_25_40_63_5_5_9_55_21_10_30_100_75_75_100_74_71_6_34_35_40_16_26_64_85_61_0_15_52_98_83_46_22_82_99_12_83_28_55_45_56_61_10_65_76_22_58_43_10_30_100_75_75_100_69_70_85_45_69_4_57_66_7_46_82_7_9_41_0_90_66_21_50_72_92_89_41_32_78_0_38_37_7_42_78_22_2_10_30_100_75_75_100',
//       // 'gene_87_1_26_40_33_15_83_47_59_27_7_92_76_33_52_1_72_86_99_82_39_69_73_12_26_91_71_58_3_73_36_52_17_10_30_100_75_75_100_53_28_37_31_47_79_93_59_83_72_37_59_19_35_81_25_56_95_49_51_63_28_4_23_48_26_30_28_60_66_91_84_24_10_30_100_75_75_100_8_51_59_36_47_12_62_47_62_42_6_19_1_57_66_93_93_3_32_34_23_2_60_48_79_100_73_38_68_22_89_31_6_10_30_100_75_75_100',
//       // 'gene_85_3_22_71_97_99_8_63_59_39_58_46_81_97_8_47_80_87_46_16_70_18_40_28_0_58_59_42_5_21_65_87_44_10_30_100_75_75_100_89_27_7_38_19_5_76_3_79_96_98_9_17_19_98_58_25_98_67_9_88_78_20_35_94_29_45_61_19_56_85_38_44_10_30_100_75_75_100_16_49_16_78_100_10_12_4_18_31_73_23_3_19_21_92_92_92_74_3_2_31_56_100_43_80_92_7_95_4_94_67_23_10_30_100_75_75_100',
//       // 'gene_53_64_94_71_90_20_41_73_46_67_37_74_61_97_31_59_70_79_41_18_38_70_14_95_84_36_82_39_58_16_28_80_45_10_30_100_75_75_100_0_75_68_17_58_49_88_61_8_73_15_78_32_61_80_16_34_56_14_36_93_70_25_36_68_10_44_97_25_79_95_53_72_10_30_100_75_75_100_26_12_28_13_100_15_62_4_22_38_50_0_21_69_0_13_17_71_63_34_68_33_63_40_51_17_37_95_58_99_95_56_9_10_30_100_75_75_100',
//       // 'gene_84_64_94_40_35_13_78_0_63_19_37_74_63_78_44_59_14_42_99_43_59_55_32_28_55_5_76_34_40_10_61_77_67_10_30_100_75_75_100_75_89_39_14_44_25_29_70_87_77_68_79_21_61_82_78_60_48_1_52_59_48_55_26_68_71_50_97_100_44_44_88_58_10_30_100_75_75_100_26_91_9_77_46_13_62_59_44_38_90_14_11_34_6_5_92_78_36_14_80_16_60_47_13_97_34_38_57_76_89_97_76_10_30_100_75_75_100',
//       // 'gene_90_79_68_40_63_16_45_54_12_87_23_53_81_97_14_71_80_76_41_62_57_52_27_95_74_68_82_34_82_82_52_57_90_10_30_100_75_75_100_89_8_50_10_79_26_88_5_62_99_34_13_29_8_89_16_22_58_55_36_88_70_25_36_88_37_25_63_13_79_97_52_72_10_30_100_75_75_100_78_93_26_49_50_1_58_21_45_33_43_0_18_19_64_86_35_7_9_34_72_33_63_40_49_17_54_37_10_26_88_33_6_10_30_100_75_75_100',
//       // 'gene_36_0_39_16_86_14_67_18_55_27_47_91_35_100_38_29_13_71_46_46_21_47_26_21_75_5_97_67_7_70_42_67_65_10_30_100_75_75_100_94_21_6_36_70_8_97_3_65_99_29_10_11_38_98_15_22_100_3_44_1_77_98_90_67_23_25_6_15_79_63_31_23_10_30_100_75_75_100_35_44_76_11_62_56_53_19_96_90_93_68_5_41_40_37_98_41_5_47_69_67_41_93_39_16_46_78_81_31_93_57_21_10_30_100_75_75_100',
//       // 'gene_88_61_41_80_29_11_66_23_62_19_26_59_93_76_51_56_54_70_73_14_61_79_74_88_2_36_67_4_0_3_61_100_70_10_30_100_75_75_100_92_78_7_33_47_16_99_7_92_96_22_0_40_20_97_16_59_56_10_9_97_33_49_47_68_29_49_0_14_65_47_82_62_10_30_100_75_75_100_42_89_26_17_88_24_62_66_42_89_30_54_12_62_48_10_30_69_74_11_1_26_46_7_51_87_99_39_0_25_87_38_21_10_30_100_75_75_100',
//       // 'gene_29_69_39_61_15_39_83_84_44_39_13_79_81_67_51_58_72_67_94_15_43_75_14_8_95_30_60_97_3_85_75_95_57_10_30_100_75_75_100_94_92_48_36_47_77_97_7_90_88_62_12_21_20_76_90_63_96_1_14_87_48_17_27_71_34_18_54_56_27_94_83_52_10_30_100_75_75_100_5_88_12_19_100_26_15_49_27_65_6_21_10_9_68_29_66_39_76_7_81_78_46_100_45_100_56_89_62_19_91_32_20_10_30_100_75_75_100',
//       // 'gene_22_9_100_24_53_65_69_23_70_100_19_81_74_34_14_59_71_45_16_58_76_2_99_4_84_63_13_80_41_78_25_94_68_10_30_100_75_75_100_58_33_38_33_47_3_79_3_28_94_35_79_16_36_9_52_0_92_13_9_59_75_43_23_67_80_33_50_24_11_31_53_80_10_30_100_75_75_100_83_87_14_0_40_8_57_4_86_60_44_14_8_35_66_92_33_70_71_34_0_33_95_100_74_16_43_46_100_69_79_65_98_10_30_100_75_75_100',
//       // 'gene_89_82_100_59_35_39_58_9_20_39_53_95_48_34_51_57_56_45_74_14_37_60_72_58_20_63_15_88_88_22_75_23_57_10_30_100_75_75_100_0_24_42_13_22_26_94_1_88_83_96_76_33_36_92_25_0_90_63_11_90_56_51_86_68_82_75_38_13_65_62_96_75_10_30_100_75_75_100_27_40_34_17_36_16_57_6_59_87_49_22_0_62_20_9_33_6_77_88_72_75_88_32_88_88_100_90_97_75_86_62_8_10_30_100_75_75_100',
//       // 'gene_81_22_20_2_41_27_12_0_93_55_20_50_61_50_83_36_97_95_57_9_90_52_82_95_8_80_70_92_10_38_63_84_88_10_30_100_75_75_100_50_15_95_54_39_99_11_26_71_81_83_99_11_79_14_75_12_64_94_46_29_47_8_26_54_71_24_23_76_88_82_26_55_10_30_100_75_75_100_100_62_13_12_62_13_67_51_48_98_35_1_0_76_13_40_50_31_89_6_20_95_26_79_12_10_20_31_35_62_99_30_45_10_30_100_75_75_100',
//       // 'gene_61_37_79_19_29_33_64_0_42_63_53_5_11_85_51_29_90_84_90_5_65_48_52_71_44_53_80_23_49_27_27_83_61_10_30_100_75_75_100_53_94_12_25_35_60_38_95_67_64_63_15_11_75_31_71_38_16_88_27_11_57_70_38_88_8_34_77_10_68_93_29_27_10_30_100_75_75_100_65_3_14_100_70_8_81_26_73_85_24_1_6_45_60_58_24_7_91_6_48_95_28_10_23_70_100_11_86_10_68_91_23_10_30_100_75_75_100',
//       // 'gene_63_3_32_2_23_64_100_77_33_93_94_78_20_85_78_16_84_0_79_8_90_6_60_67_8_53_99_58_50_31_39_50_57_10_30_100_75_75_100_68_71_44_75_5_94_13_54_37_90_34_24_12_32_10_71_44_35_76_27_22_42_91_53_96_69_43_97_96_47_74_43_28_10_30_100_75_75_100_43_28_100_29_56_0_50_60_66_28_55_1_13_67_34_59_3_70_92_21_47_96_25_78_19_34_60_95_54_67_75_19_5_10_30_100_75_75_100',
//       // 'gene_46_0_12_0_25_55_92_0_77_93_85_59_61_17_95_54_80_63_0_0_44_6_44_5_8_45_96_87_41_28_2_54_7_10_30_100_75_75_100_47_26_84_47_35_48_44_99_31_88_65_10_7_77_14_84_38_38_18_42_22_53_94_21_15_92_47_100_83_24_90_42_26_10_30_100_75_75_100_57_37_86_100_79_55_79_2_62_89_31_1_7_45_38_47_0_55_38_25_48_74_2_9_19_22_98_36_54_54_70_87_22_10_30_100_75_75_100',
//       // 'gene_75_37_51_13_81_65_98_12_18_93_91_28_17_5_79_57_94_0_12_77_95_42_58_47_2_61_87_93_14_12_95_26_60_10_30_100_75_75_100_64_75_26_38_72_74_19_24_78_99_96_78_0_35_22_83_77_42_88_34_43_37_53_51_98_18_33_90_62_44_89_72_59_10_30_100_75_75_100_5_38_91_6_71_100_32_55_28_57_58_0_9_46_9_9_21_7_81_78_10_96_40_69_44_73_81_30_90_6_74_85_18_10_30_100_75_75_100',
//       // 'gene_81_37_56_83_81_44_99_0_75_65_89_62_5_60_69_17_93_20_53_61_78_80_10_77_10_44_100_26_46_41_10_83_71_10_30_100_75_75_100_66_26_73_71_62_21_1_32_35_12_49_41_11_21_31_71_45_57_90_20_98_76_16_28_82_93_26_43_26_47_85_42_31_10_30_100_75_75_100_88_37_93_39_63_51_22_43_6_28_81_38_4_45_7_0_24_62_28_21_47_77_48_53_20_74_88_72_80_6_76_97_15_10_30_100_75_75_100',
//       // 'gene_96_61_49_14_57_5_100_6_9_28_87_31_1_60_83_8_20_85_97_32_85_66_47_49_71_56_73_58_74_39_4_85_62_10_30_100_75_75_100_52_83_52_48_39_17_32_30_23_82_49_90_0_100_24_71_96_19_32_9_30_83_72_63_61_16_7_21_66_21_71_56_98_10_30_100_75_75_100_39_61_100_12_54_60_84_18_85_57_58_65_4_44_11_10_57_5_93_59_54_73_37_31_30_70_26_30_34_4_83_97_34_10_30_100_75_75_100',
//       // 'gene_34_22_5_48_80_66_46_18_77_4_20_24_59_55_11_49_56_15_100_68_90_23_68_62_27_53_67_54_53_45_8_37_52_10_30_100_75_75_100_50_20_95_45_20_20_13_26_31_100_7_83_10_79_34_53_51_61_94_2_61_8_5_26_99_5_20_67_62_88_81_39_89_10_30_100_75_75_100_38_62_100_84_62_95_76_44_22_98_30_0_0_76_55_5_63_25_88_24_41_75_36_9_49_29_20_31_87_8_93_65_81_10_30_100_75_75_100',
//       // 'gene_73_3_15_63_25_45_99_57_37_93_64_5_1_85_76_80_55_56_81_8_65_13_1_53_75_50_100_58_49_89_39_85_67_10_30_100_75_75_100_47_92_93_56_30_15_7_23_12_40_34_41_27_32_15_67_6_41_88_32_59_84_75_62_38_71_83_98_42_43_85_39_33_10_30_100_75_75_100_45_28_77_29_59_5_94_58_5_52_39_0_8_45_12_16_3_70_89_21_42_92_30_96_20_71_60_95_60_0_42_86_15_10_30_100_75_75_100',
//       // 'gene_20_27_14_0_7_61_2_12_86_66_21_78_61_37_81_80_72_19_92_58_74_94_30_43_0_57_0_85_46_54_10_61_89_10_30_100_75_75_100_61_83_23_75_49_28_73_39_39_100_93_18_11_55_4_78_10_13_71_59_51_58_32_37_90_27_17_22_26_5_100_59_33_10_30_100_75_75_100_68_60_81_17_63_71_65_72_85_76_30_28_4_100_95_2_97_11_31_28_44_96_43_61_27_80_61_3_82_13_80_45_36_10_30_100_75_75_100',
//       // 'gene_23_96_8_36_72_43_95_59_22_53_70_18_16_90_27_10_100_47_75_5_22_75_47_23_20_30_87_79_34_69_52_61_55_10_30_100_75_75_100_30_71_26_81_54_19_58_25_100_8_79_26_1_38_4_74_84_64_89_86_68_75_25_68_41_39_76_39_26_56_61_62_68_10_30_100_75_75_100_10_59_96_30_65_32_100_28_61_6_100_56_19_20_0_75_27_100_88_14_94_12_78_64_16_24_100_88_69_75_48_7_92_10_30_100_75_75_100',
//       // 'gene_79_90_67_28_72_43_68_17_53_0_68_18_29_86_27_4_100_46_86_87_87_66_76_23_17_30_85_95_97_66_24_37_75_10_30_100_75_75_100_75_10_84_21_97_45_92_25_98_8_65_3_42_45_4_83_57_33_95_86_84_78_4_81_49_61_49_93_98_59_61_62_5_10_30_100_75_75_100_92_59_91_78_68_29_62_28_61_6_51_49_19_20_14_41_96_100_61_65_97_48_78_46_30_54_23_36_38_75_100_7_80_10_30_100_75_75_100',
//       // 'gene_40_6_64_59_68_100_31_78_60_26_78_40_71_36_77_30_93_33_74_8_53_69_33_29_67_17_94_55_21_36_65_31_59_10_30_100_75_75_100_99_48_50_20_92_19_59_25_27_12_85_18_5_47_53_95_0_54_60_28_73_73_19_62_61_90_79_93_21_94_87_67_9_10_30_100_75_75_100_42_62_92_29_84_1_0_6_12_65_46_28_15_39_38_53_19_100_47_15_32_9_35_51_16_70_34_61_66_72_54_89_76_10_30_100_75_75_100',
//       // 'gene_81_81_29_97_43_11_93_70_21_99_94_37_20_23_77_20_93_85_18_6_24_42_33_80_59_77_21_15_26_23_53_92_75_10_30_100_75_75_100_57_44_62_95_37_31_25_15_96_91_76_25_29_40_20_71_5_16_95_36_81_74_32_81_44_0_52_83_67_75_52_57_15_10_30_100_75_75_100_42_64_92_48_66_46_3_4_90_58_96_49_27_51_29_14_96_0_97_16_82_42_31_84_2_22_34_46_41_72_93_18_89_10_30_100_75_75_100',
//       // 'gene_28_52_86_79_77_61_35_50_21_56_32_29_28_44_33_62_77_52_74_18_15_70_60_85_55_86_81_37_26_70_2_35_40_10_30_100_75_75_100_49_48_57_17_37_47_67_28_100_30_62_32_29_95_77_73_0_55_60_7_78_31_24_72_69_53_31_88_54_21_94_61_70_10_30_100_75_75_100_83_41_83_25_77_21_54_40_44_3_47_40_20_18_18_22_1_10_97_14_97_45_8_85_49_72_53_100_14_74_95_7_90_10_30_100_75_75_100',
//       // 'gene_24_80_67_62_73_61_99_88_95_53_88_40_28_57_25_58_47_47_84_83_82_60_44_28_9_88_88_28_26_19_70_56_75_10_30_100_75_75_100_92_32_26_78_46_45_67_78_89_27_7_3_44_43_17_38_7_22_15_41_51_0_9_36_69_36_72_93_65_50_61_64_63_10_30_100_75_75_100_19_41_82_68_76_30_12_33_10_58_48_47_34_80_37_23_22_78_60_15_20_55_72_39_45_73_20_100_36_38_46_68_75_10_30_100_75_75_100',
//       // 'gene_68_97_61_27_40_5_49_90_23_82_67_35_22_43_29_89_71_85_14_100_66_73_49_32_54_37_6_82_34_19_17_5_62_10_30_100_75_75_100_98_71_26_20_45_19_94_23_100_95_71_27_37_80_11_1_17_54_41_0_74_73_20_53_37_57_83_22_25_32_39_46_18_10_30_100_75_75_100_89_54_44_39_68_82_7_60_90_100_32_5_28_43_4_91_20_7_48_14_93_45_15_21_5_80_55_38_29_70_40_7_87_10_30_100_75_75_100',
//       // 'gene_86_29_22_100_66_93_30_88_71_0_68_65_96_90_46_20_93_66_43_9_16_66_29_86_59_24_87_82_26_63_65_30_100_10_30_100_75_75_100_5_48_60_67_60_20_96_45_98_34_70_18_12_46_9_76_85_53_15_49_100_12_59_82_59_37_37_79_17_18_93_78_52_10_30_100_75_75_100_86_43_83_16_48_21_2_7_20_56_53_55_24_50_35_80_94_81_48_79_100_45_18_94_82_100_33_47_39_76_75_30_85_10_30_100_75_75_100',
//       // 'gene_31_37_12_92_64_5_2_71_89_69_70_30_36_21_77_18_77_45_18_59_20_2_28_89_21_22_15_28_85_43_74_8_63_10_30_100_75_75_100_36_85_63_22_88_27_63_60_24_78_53_10_22_32_57_72_81_60_29_0_22_75_24_77_32_30_72_88_69_6_62_29_82_10_30_100_75_75_100_78_48_83_89_84_47_2_4_13_56_48_42_13_74_35_66_52_77_9_13_2_85_0_94_46_76_32_2_69_14_34_23_76_10_30_100_75_75_100',
//       // 'gene_6_74_15_100_78_5_24_47_60_100_21_86_13_90_27_6_91_58_51_0_93_64_81_22_61_10_89_20_34_76_63_74_47_10_30_100_75_75_100_50_48_63_43_96_24_90_0_92_0_19_65_41_80_2_80_0_53_36_19_82_75_3_17_94_57_36_91_14_0_49_79_88_10_30_100_75_75_100_79_54_83_20_79_36_2_60_24_58_50_40_27_50_38_74_90_59_45_90_100_21_94_49_22_84_97_44_36_70_48_28_68_10_30_100_75_75_100',
//       // 'gene_52_96_91_23_92_40_57_11_62_99_82_46_68_26_55_20_100_94_35_29_15_64_79_84_0_82_81_25_38_0_99_43_24_10_30_100_75_75_100_11_85_17_12_78_10_86_13_83_33_93_83_12_61_23_33_12_0_63_39_74_50_36_14_44_19_58_70_62_77_67_6_79_10_30_100_75_75_100_21_0_87_10_83_17_65_25_79_69_20_7_6_74_54_34_22_33_93_25_100_28_46_34_20_77_67_27_6_20_59_37_53_10_30_100_75_75_100',
//       // 'gene_48_58_34_96_92_39_49_20_65_74_93_77_72_62_0_55_3_35_55_47_20_99_83_86_16_80_38_88_79_3_50_90_27_10_30_100_75_75_100_68_29_49_70_77_45_42_14_37_35_74_29_4_34_63_33_97_66_0_49_82_35_59_17_16_53_40_0_88_49_85_3_36_10_30_100_75_75_100_17_28_60_29_68_15_57_24_76_69_100_19_11_14_51_45_31_64_69_82_100_48_79_3_14_54_100_18_36_66_90_46_26_10_30_100_75_75_100',
//       // 'gene_93_28_11_64_8_28_66_60_79_53_60_36_57_95_25_9_99_35_58_20_27_79_24_49_87_20_72_62_84_1_50_51_34_10_30_100_75_75_100_34_98_81_68_41_42_28_8_4_37_14_82_12_31_100_29_10_16_78_28_76_20_59_73_69_22_81_96_98_40_43_13_79_10_30_100_75_75_100_100_55_70_29_70_17_65_18_78_64_26_41_7_39_48_75_69_36_87_72_95_18_23_21_46_29_84_91_31_22_59_45_54_10_30_100_75_75_100',
//       // 'gene_52_57_35_69_96_78_82_37_11_56_14_94_64_84_27_3_25_41_59_26_20_80_81_84_14_73_62_46_34_28_46_49_31_10_30_100_75_75_100_39_85_45_81_78_65_94_59_32_6_68_88_6_31_72_82_97_87_26_3_97_13_36_55_7_16_76_71_82_77_51_75_33_10_30_100_75_75_100_96_0_89_98_51_58_41_8_75_79_75_32_7_64_59_79_54_68_98_79_19_16_72_23_24_17_71_59_69_90_69_46_2_10_30_100_75_75_100',
//       // 'gene_57_3_35_69_94_78_35_32_79_17_14_94_9_98_33_41_68_34_24_67_20_80_24_84_11_28_16_59_89_67_99_42_17_10_30_100_75_75_100_84_85_36_60_86_65_97_24_82_81_68_10_6_35_90_82_36_6_96_3_55_87_36_14_30_16_100_16_53_74_51_2_33_10_30_100_75_75_100_65_0_82_98_51_32_19_26_75_65_100_38_9_47_48_88_54_5_83_16_68_57_76_25_88_62_64_59_70_18_69_51_30_10_30_100_75_75_100',
//       // 'gene_49_0_81_29_8_42_86_28_79_71_84_94_62_51_93_39_20_40_56_9_15_65_12_81_1_57_50_68_97_86_84_94_24_10_30_100_75_75_100_58_82_89_63_47_39_88_15_78_91_57_10_56_100_34_39_4_16_34_20_74_18_38_13_26_4_18_79_62_11_74_7_78_10_30_100_75_75_100_3_45_63_19_60_34_69_19_76_69_31_12_3_13_46_19_68_30_88_13_2_100_59_1_98_32_75_58_69_93_75_46_77_10_30_100_75_75_100',
//       // 'gene_66_29_27_84_19_76_8_20_23_62_19_77_72_28_29_74_20_35_62_85_15_87_97_97_58_80_90_14_79_2_49_53_31_10_30_100_75_75_100_53_20_86_70_12_73_12_34_79_64_68_42_7_94_34_87_97_18_0_89_62_35_94_63_66_17_14_51_88_49_79_3_27_10_30_100_75_75_100_100_32_87_19_79_29_59_4_18_95_86_41_11_73_44_68_72_64_69_10_86_50_78_2_63_54_75_18_33_89_72_49_12_10_30_100_75_75_100',
//       // 'gene_75_20_30_64_9_57_100_28_56_11_35_76_65_31_19_78_56_31_84_26_87_88_29_38_8_75_90_21_87_60_85_12_54_10_30_100_75_75_100_53_78_26_25_44_55_33_14_82_84_63_4_7_53_72_91_0_6_79_15_43_90_39_14_66_69_70_74_96_80_59_0_90_10_30_100_75_75_100_37_12_45_37_94_27_71_23_86_94_85_3_3_64_66_62_100_63_84_27_37_80_35_30_16_78_75_72_71_95_72_47_34_10_30_100_75_75_100',
//       // 'gene_43_38_35_27_2_45_100_69_17_28_43_36_68_31_25_72_86_9_69_54_19_20_3_33_58_70_92_44_62_0_83_62_24_10_30_100_75_75_100_71_75_82_68_42_37_42_86_68_0_40_8_4_77_65_92_86_25_28_17_23_93_55_31_70_14_79_24_52_81_60_11_27_10_30_100_75_75_100_100_99_59_86_94_25_71_25_0_71_100_19_4_51_54_69_60_81_95_92_100_0_26_10_97_78_75_48_63_32_72_73_97_10_30_100_75_75_100',
//       // 'gene_61_29_10_58_79_31_98_79_22_66_86_76_67_51_25_91_20_35_40_14_14_95_47_86_22_96_15_26_83_2_40_45_41_10_30_100_75_75_100_45_9_61_5_47_38_81_15_46_35_56_0_39_26_19_95_20_3_0_33_76_20_95_14_63_17_11_77_8_36_100_14_43_10_30_100_75_75_100_100_76_79_19_63_91_19_26_74_79_78_44_6_71_52_24_85_1_67_31_87_57_54_73_22_53_66_23_68_10_72_51_29_10_30_100_75_75_100',
//       'genes_100_78_55_56_70_16_26_18_42_13_83_95_62_87_82_57_22_21_0_57_14_1_73_17_54_70_64_15_27_68_15_50_100_89_86_7_32_18_78_26_97_69_19_88_55_76_13_80_78_9_61_78_80_57_75_22_74_39_46_19_37_75_56_47_30_25_33_65_45_38_76_10_100_28_49_37_66_50_23_43_5_100_96_41_0_6_85_99_73_16_14_64_95_1_44_21_10_6_56_57_80_39_17_74_71_50_0_89_42_94_78_97_15_100_28_61_64_23_33_62',
//       'genes_29_29_2_56_99_50_55_64_92_35_82_10_62_10_82_24_53_66_60_96_32_47_73_91_49_54_61_20_1_23_64_29_100_75_73_47_29_25_78_29_82_63_1_69_78_22_98_41_53_20_73_27_28_39_20_42_60_43_98_54_30_3_39_6_47_10_26_33_54_19_61_59_100_31_54_18_50_97_21_6_39_27_71_55_4_0_43_81_66_36_100_37_0_57_5_21_83_10_55_37_60_72_4_25_85_59_47_60_80_45_83_0_40_100_4_93_60_69_22_68',
//       'genes_14_50_55_66_70_50_42_36_37_22_82_99_68_5_80_44_45_98_87_62_85_38_73_51_59_56_39_48_0_72_96_80_100_91_10_91_80_23_6_95_96_59_19_67_77_28_4_5_86_7_26_55_84_40_19_52_81_39_19_17_83_91_56_7_100_2_23_6_12_48_23_92_100_100_43_18_66_58_5_77_92_85_8_41_6_5_20_86_11_19_46_50_63_81_5_39_48_2_57_100_17_30_70_50_20_18_41_66_46_69_21_68_72_100_64_61_63_98_33_22',
//       'genes_81_73_29_24_59_79_11_19_76_30_86_85_17_5_19_49_25_25_71_15_78_18_13_70_85_56_60_48_96_69_94_79_100_42_88_100_33_84_89_97_97_22_71_94_65_40_0_58_53_58_46_74_36_22_28_95_79_63_79_22_57_99_6_34_45_6_80_91_12_22_28_90_100_65_67_78_95_51_36_43_71_19_73_11_59_6_21_69_87_52_94_66_62_25_4_83_8_13_25_73_58_68_92_0_98_33_43_28_46_88_8_55_41_100_6_54_45_45_4_55',
//       'genes_56_92_43_56_14_50_92_86_37_31_85_14_76_5_70_57_75_23_0_13_32_26_73_93_70_54_12_84_27_95_55_46_100_90_75_100_28_7_10_84_100_88_0_61_63_98_37_20_50_10_100_27_55_59_27_25_8_33_100_31_19_3_62_91_26_6_37_11_78_64_36_59_100_15_12_78_0_60_32_10_62_66_82_41_54_3_34_99_4_53_31_75_22_95_55_25_48_19_25_37_74_34_30_98_20_18_33_66_43_45_23_0_6_100_61_26_9_87_34_68',
//       'genes_61_21_66_60_62_16_50_21_47_59_8_14_75_66_85_38_51_74_32_60_4_35_56_47_72_60_25_98_26_18_47_46_100_80_70_92_29_2_4_79_10_47_81_69_84_51_0_86_58_88_73_77_14_62_55_25_68_82_50_91_20_75_55_7_95_2_33_12_82_61_37_16_100_29_11_77_59_60_14_31_68_100_88_52_16_13_21_91_69_25_10_35_75_26_96_60_88_100_25_23_80_67_13_4_18_35_5_33_9_78_74_93_62_100_64_46_45_29_8_3',
//       'genes_58_50_54_60_70_74_42_60_97_24_4_28_65_70_70_52_44_34_58_38_40_38_90_93_58_56_47_53_18_44_43_29_100_92_100_43_68_7_85_9_93_74_34_62_78_43_37_55_48_33_72_55_33_76_20_81_0_67_91_27_41_59_40_96_13_76_78_11_4_19_49_90_100_39_81_77_67_50_14_93_38_64_8_42_6_3_72_55_35_57_93_92_71_61_96_24_65_85_18_100_73_34_65_2_94_100_41_66_35_7_5_82_10_100_4_19_48_54_26_55',
//       'genes_14_32_18_66_16_53_93_70_95_29_82_52_61_10_17_43_55_100_4_41_79_97_81_51_42_71_61_44_51_4_0_98_100_92_75_43_33_81_36_79_88_59_60_10_79_13_0_78_53_11_59_28_85_90_16_43_21_92_98_26_54_72_3_48_99_22_27_55_12_47_47_90_100_36_81_82_70_66_16_21_36_100_1_34_4_3_17_27_66_23_88_52_59_1_54_49_28_16_89_87_16_39_43_0_91_20_44_96_76_52_34_4_33_100_24_44_62_98_37_68',
//       'genes_61_85_10_60_40_59_25_63_13_24_83_78_87_42_80_56_95_21_4_22_63_20_81_66_44_56_18_27_81_33_100_78_100_60_88_39_33_82_80_29_25_47_6_65_40_73_8_83_78_64_99_60_16_35_74_16_56_68_57_17_41_99_62_64_33_6_30_86_30_14_45_74_100_59_46_71_63_18_72_43_69_59_76_70_24_8_59_90_66_83_12_34_63_81_22_17_22_56_32_74_12_4_0_5_39_40_18_28_86_1_17_1_66_100_16_51_64_98_52_70',
//       'genes_9_39_51_72_61_56_50_55_40_23_81_54_4_73_85_57_22_98_46_93_67_19_0_42_49_95_44_25_94_72_95_50_100_15_48_96_15_82_89_78_50_68_10_89_67_74_12_16_58_86_72_52_37_53_16_25_59_37_99_26_41_82_67_85_67_23_78_52_58_4_11_16_100_58_66_43_55_54_67_38_38_97_75_12_18_35_79_81_90_16_13_8_72_6_55_24_73_21_58_74_80_93_13_50_38_79_36_27_49_4_0_92_66_100_21_59_45_69_88_11',
//       'genes_34_73_76_93_22_43_92_64_97_66_4_92_33_5_71_38_21_44_89_36_67_78_57_46_0_82_59_9_90_68_14_45_100_84_54_17_30_19_13_94_9_89_77_98_91_65_0_23_44_64_29_64_95_86_23_90_11_71_39_11_6_68_56_91_26_55_45_52_32_0_87_47_100_35_11_74_53_5_7_93_42_66_75_0_38_1_19_83_8_16_36_74_34_43_88_4_31_98_13_95_16_66_8_0_100_92_84_92_41_55_26_13_10_100_4_82_9_73_26_14',
//       'genes_8_11_15_50_3_53_37_72_11_12_42_56_99_67_20_87_31_19_85_57_19_41_69_58_62_37_25_49_29_100_2_45_100_31_75_28_89_91_11_2_81_74_14_17_79_67_99_83_78_48_49_82_96_59_19_32_21_40_98_10_35_75_54_5_44_73_30_89_85_4_14_93_100_44_82_81_57_98_14_77_36_61_24_73_15_6_58_28_68_80_56_72_61_45_15_49_28_41_19_96_21_71_4_45_91_49_47_28_35_52_8_0_81_100_61_42_45_88_25_22',
//       'genes_100_8_72_56_14_7_49_38_100_33_7_24_99_42_54_12_92_72_66_15_28_64_52_69_71_37_24_25_34_62_92_18_100_88_78_66_48_81_13_39_28_69_63_57_53_33_8_21_40_10_51_41_100_41_23_73_98_75_96_67_41_95_58_7_8_2_33_82_78_61_8_6_100_24_49_53_8_86_42_41_71_88_76_13_46_50_84_55_70_3_100_74_60_45_51_21_8_100_59_23_95_39_44_61_40_96_90_16_35_51_88_2_10_100_95_62_65_58_10_59',
//       'genes_100_78_62_7_64_67_43_19_44_28_59_56_48_66_34_39_54_100_7_15_84_66_8_22_61_37_47_31_88_62_69_46_100_91_88_66_74_88_12_39_35_29_67_66_64_43_6_19_42_39_25_74_82_22_28_8_53_29_80_67_22_34_54_81_11_47_39_78_82_3_72_97_100_24_10_77_10_55_56_43_36_91_78_64_47_13_85_58_73_72_99_48_64_4_90_83_32_15_90_30_73_72_24_47_44_50_90_92_86_23_95_60_10_100_61_49_45_87_5_33',
//       'genes_61_21_62_27_14_40_87_86_84_31_16_83_87_41_79_19_76_44_25_56_67_26_7_56_70_82_59_8_27_65_83_46_100_85_75_17_68_80_57_29_91_30_8_74_65_43_12_63_22_3_97_100_22_32_65_72_47_40_85_64_19_84_58_82_36_14_66_97_63_59_91_55_100_91_11_77_1_18_64_43_31_100_19_36_70_0_58_100_95_4_63_13_69_95_0_86_43_13_46_49_79_76_8_0_54_91_39_100_81_32_23_92_30_100_26_54_100_58_88_59',
//       'genes_100_13_15_60_37_53_42_38_11_71_88_97_76_70_70_52_44_74_0_75_46_38_90_56_92_60_44_54_63_10_43_82_100_65_100_69_74_91_30_0_93_96_29_56_72_69_0_53_53_85_71_55_33_59_23_78_0_37_62_10_28_59_40_100_44_76_29_86_5_31_83_54_100_35_59_33_98_61_14_38_71_90_8_69_1_13_72_46_82_7_93_92_71_78_81_3_43_41_59_100_73_93_65_2_86_46_49_98_39_75_21_92_10_100_61_19_45_33_25_19',
//       'genes_64_80_67_7_40_79_42_63_88_26_49_48_65_71_78_56_95_68_32_95_36_66_79_66_56_11_25_27_8_37_22_58_100_63_93_39_33_27_80_29_70_36_83_88_66_22_0_74_78_68_70_59_57_67_74_99_94_48_57_27_42_72_18_64_33_6_46_86_30_53_21_93_100_71_77_77_74_18_56_43_73_19_23_70_6_12_85_14_8_44_12_1_63_81_52_21_12_63_20_95_15_14_62_5_15_36_49_93_46_55_9_1_71_100_25_16_48_75_74_27',
//       'genes_10_17_50_45_41_60_84_31_81_69_72_54_99_9_85_38_5_74_32_75_80_41_12_43_58_50_30_25_74_33_0_49_100_90_46_48_75_82_19_78_28_77_61_85_24_81_9_16_44_31_29_59_90_67_26_90_78_86_96_26_41_50_35_48_28_0_78_20_73_53_96_52_100_37_51_18_58_93_11_93_13_90_29_58_4_6_36_55_82_56_31_60_78_82_81_24_39_46_90_59_16_68_63_50_65_100_25_22_41_75_21_81_80_100_27_11_61_69_19_57',
//       'genes_61_23_69_60_40_100_22_35_47_56_11_23_20_25_70_57_52_74_5_52_3_41_56_56_57_56_25_48_13_18_94_28_100_100_80_96_75_35_78_77_25_47_60_100_61_44_9_81_53_23_2_45_92_65_20_16_1_67_58_15_93_75_67_4_36_6_25_97_46_57_47_50_100_24_46_43_36_49_68_96_69_68_74_72_51_5_97_54_76_40_3_63_60_53_9_21_71_56_61_53_74_43_4_2_42_54_93_28_76_94_8_97_33_100_65_61_60_60_22_68',
//       'genes_90_26_65_60_14_78_57_38_82_12_85_56_75_87_20_69_33_5_32_57_19_35_81_52_62_54_25_49_77_14_38_29_100_80_50_91_85_2_4_81_10_74_55_69_84_30_0_83_78_8_98_44_6_59_25_25_68_23_50_68_67_75_54_5_35_6_20_12_5_65_37_97_100_44_11_81_59_49_39_39_69_53_2_73_15_4_58_91_65_39_61_72_72_81_15_26_27_95_18_47_63_67_30_50_34_46_23_28_9_66_8_55_10_100_66_79_47_60_26_21',
//       'genes_9_85_11_60_55_51_92_12_93_58_81_59_95_51_70_0_44_74_5_63_3_35_82_56_19_68_50_62_71_18_94_100_100_87_49_7_75_27_89_35_63_47_60_69_67_44_9_83_98_65_73_27_63_65_20_14_0_40_97_56_39_75_3_97_17_63_25_87_68_31_47_59_100_51_70_19_73_66_67_29_71_86_23_72_17_5_56_10_5_57_100_50_75_61_96_24_43_100_7_87_27_81_25_2_95_18_96_88_86_94_6_93_33_100_5_49_42_13_52_24',
//       'genes_58_59_72_56_69_53_56_60_97_22_2_59_72_71_19_40_0_65_58_44_45_37_16_93_58_65_60_9_53_44_62_45_100_26_92_25_51_7_85_29_98_69_87_63_67_33_9_86_50_7_37_55_61_76_20_89_10_31_100_27_42_73_8_96_44_10_75_11_4_65_29_91_100_16_54_77_49_51_29_66_38_100_77_41_6_53_62_45_35_5_11_93_9_1_96_2_33_15_19_93_73_34_65_64_20_100_37_95_35_71_88_82_84_100_4_91_48_98_88_55',
//       'genes_58_50_54_49_61_79_91_91_97_79_93_54_42_71_70_34_42_4_36_53_83_26_16_93_58_65_50_9_56_69_60_27_100_91_46_46_34_7_61_81_11_74_88_62_67_33_15_86_50_33_26_56_90_80_26_89_10_36_100_67_41_50_8_7_44_0_27_85_4_14_46_100_100_14_93_74_55_47_68_64_38_64_75_41_6_3_34_55_35_5_26_98_80_61_75_74_17_39_59_100_17_98_25_98_20_32_22_66_86_77_17_82_84_100_2_26_46_67_46_58',
//       'genes_29_21_18_66_43_60_94_88_69_23_79_25_66_27_52_44_58_23_71_99_18_69_10_50_62_59_41_31_27_41_60_73_100_87_8_98_31_91_83_0_88_69_0_40_67_67_3_20_54_64_72_82_96_65_29_90_3_45_13_15_40_94_34_48_86_95_25_19_69_55_29_95_100_37_13_35_70_5_97_75_91_100_35_7_4_4_39_26_8_93_10_57_64_1_49_24_28_100_29_57_59_19_13_79_88_45_95_100_86_89_95_66_84_100_85_46_45_87_26_14',
//       'genes_29_8_2_60_37_63_55_50_11_59_37_10_62_14_70_49_58_11_5_63_3_47_0_91_42_54_25_19_13_18_95_25_100_89_49_47_33_75_89_79_25_51_54_67_56_22_9_4_98_20_73_55_44_39_28_63_1_67_65_17_38_75_97_2_15_22_25_87_12_42_52_52_100_80_46_43_53_49_16_96_72_10_71_72_4_3_56_54_66_36_100_63_60_56_5_22_43_100_2_76_30_51_90_40_85_59_89_98_80_94_9_4_40_100_4_28_48_63_52_68',
//       'genes_57_20_62_56_100_53_50_38_12_33_30_24_72_71_83_44_31_72_66_41_28_61_9_66_71_71_50_25_13_62_92_3_100_41_82_80_53_81_33_41_10_30_11_57_56_39_0_5_89_57_70_52_100_41_23_73_60_48_99_69_38_95_54_12_49_2_92_85_75_55_13_96_100_24_70_82_73_86_56_39_59_91_76_38_12_50_8_11_2_3_100_74_58_1_56_21_12_63_88_18_19_81_84_22_95_60_62_96_1_85_69_2_37_100_4_62_46_73_3_58',
//       'genes_10_23_54_62_100_98_80_50_47_56_11_80_68_51_84_69_52_21_43_51_67_57_55_47_81_50_50_23_5_72_46_28_100_83_80_100_85_79_78_87_86_30_14_77_61_88_9_81_53_81_2_45_95_67_26_41_53_37_93_26_74_95_42_4_34_51_56_97_82_57_47_50_100_49_15_19_31_56_71_29_13_100_19_25_72_34_97_98_73_37_97_30_75_52_52_21_8_97_61_100_18_7_4_40_18_55_93_98_76_79_17_52_13_100_7_64_3_60_96_68',
//       'genes_29_39_24_70_70_98_22_31_43_37_11_83_35_51_81_57_50_90_27_52_2_51_98_51_81_65_60_48_76_42_56_28_100_90_80_42_85_81_78_29_82_89_25_100_63_17_9_81_53_8_24_28_97_24_63_42_54_82_88_64_74_50_65_4_26_22_25_90_12_58_29_55_100_22_54_77_10_56_72_35_70_100_54_46_16_3_0_83_71_16_97_26_77_30_10_21_74_92_55_57_19_56_4_51_18_55_49_98_76_83_25_97_47_100_5_88_60_60_22_68',
//       'genes_3_73_6_27_100_48_52_5_97_23_29_3_27_33_50_45_44_99_2_55_77_62_12_51_59_98_56_21_30_42_66_48_100_89_10_35_16_78_30_95_89_50_64_17_64_28_8_17_87_25_30_22_96_60_20_49_13_90_93_31_38_1_21_100_29_18_30_44_72_52_21_100_100_66_12_10_34_100_14_41_48_19_85_72_51_5_85_6_80_7_4_63_93_97_51_11_69_41_73_49_73_97_30_0_62_95_91_91_49_14_28_48_62_100_61_52_17_87_88_24',
//       'genes_10_67_18_91_66_88_62_88_69_23_88_47_72_42_52_54_25_23_32_99_61_69_83_53_59_49_41_48_53_69_45_45_100_91_10_7_30_28_99_17_88_47_5_17_50_33_1_59_91_82_72_70_85_65_32_27_86_81_47_68_40_21_97_96_87_78_7_96_82_45_44_10_100_53_55_82_70_25_89_96_31_100_88_7_57_55_17_55_8_72_10_57_62_1_51_21_28_95_27_25_93_39_65_2_91_79_90_91_46_55_71_70_62_100_61_13_62_79_29_19',
//       'genes_59_67_43_58_98_88_59_22_27_9_89_47_72_87_56_36_65_98_32_61_61_18_79_47_16_49_53_82_22_51_66_46_100_85_10_94_29_7_43_17_86_27_1_0_79_61_97_86_96_59_75_70_82_22_35_14_0_83_47_68_39_75_62_94_33_78_7_48_46_73_66_10_100_53_73_77_54_85_18_96_67_100_52_45_9_2_52_51_13_72_22_100_80_4_53_21_27_95_63_30_69_50_63_10_44_13_90_91_86_52_71_46_62_100_76_52_62_79_13_34',
//       'genes_77_18_37_61_97_23_94_35_39_26_88_60_87_9_82_52_26_5_90_52_78_26_98_25_85_71_27_84_90_68_82_46_100_0_50_43_31_91_10_39_81_90_60_57_84_25_0_17_53_85_72_41_82_65_75_25_3_29_90_22_39_100_60_48_47_15_21_88_13_48_5_93_100_66_13_88_58_86_12_63_48_100_74_7_86_13_43_58_91_51_99_69_77_25_51_10_100_43_88_15_73_30_35_0_70_50_43_27_89_55_9_55_17_100_57_51_37_69_26_59',
//       'genes_9_26_44_56_64_56_54_60_43_35_90_56_78_21_51_39_42_23_85_78_75_67_8_47_88_37_9_19_88_33_64_43_100_88_10_43_83_86_95_39_96_58_61_65_63_50_11_19_89_57_25_62_99_83_28_78_98_27_80_54_13_75_54_84_11_47_34_6_32_48_86_54_100_31_60_86_55_0_97_93_71_71_64_13_46_17_51_83_87_95_98_77_68_4_51_80_8_43_59_96_0_38_4_47_44_50_90_29_86_75_1_0_6_100_63_49_45_87_5_33',
//       'genes_59_60_62_66_0_56_19_70_88_13_88_56_72_10_71_22_5_100_0_44_29_38_91_70_72_65_60_31_0_26_98_31_100_30_98_82_29_79_13_79_70_69_8_57_82_34_8_87_92_20_37_24_87_39_34_90_57_44_100_26_16_79_65_9_44_0_75_44_12_79_29_96_100_16_73_51_75_0_29_89_66_100_75_62_6_51_41_14_5_61_46_93_60_1_81_2_12_15_6_100_89_48_13_40_40_60_43_25_31_75_29_4_42_100_2_91_67_84_13_14',
//       'genes_34_3_6_19_61_50_52_89_11_23_26_61_27_42_50_44_20_74_66_33_42_46_1_13_43_36_56_45_32_99_56_54_100_89_62_94_21_81_37_95_30_29_73_85_79_70_8_17_31_30_4_72_87_56_20_49_23_39_68_72_36_6_52_100_44_100_27_82_58_3_52_3_100_35_11_10_45_61_32_41_37_100_73_5_10_5_80_54_66_7_98_63_59_94_58_92_8_41_2_49_70_45_30_19_82_50_20_53_49_94_1_0_62_100_61_45_45_11_87_59',
//       'genes_38_29_18_66_14_80_58_22_100_10_82_13_32_10_57_44_92_72_64_62_86_9_90_70_85_52_39_44_0_72_76_18_100_92_100_25_48_75_6_31_81_62_63_67_56_59_4_53_53_10_58_79_95_39_47_12_62_26_14_87_41_91_58_7_8_7_34_78_12_48_23_97_100_24_69_53_53_58_26_77_69_90_8_5_15_53_0_81_66_57_46_93_63_1_24_49_11_41_59_100_95_27_70_50_25_59_73_15_80_47_14_8_68_100_2_50_65_58_5_22',
//       'genes_40_10_46_87_100_40_84_35_83_26_25_56_75_9_70_52_5_74_79_75_18_39_12_56_22_67_25_25_90_33_100_28_100_84_14_43_73_82_19_82_28_65_53_66_67_74_9_33_12_81_29_44_85_65_70_10_100_71_99_27_55_4_65_33_26_73_33_9_75_53_29_52_100_26_42_32_58_52_14_37_100_94_100_55_100_1_15_55_82_68_31_69_95_36_100_73_8_43_91_67_73_11_84_85_44_44_38_100_56_52_98_82_13_100_27_11_70_69_29_16',
//       'genes_99_62_62_27_86_40_87_22_84_19_90_16_87_23_19_49_76_25_68_10_30_39_83_47_85_37_62_86_27_69_7_79_100_85_86_17_52_80_57_94_100_46_13_74_65_51_9_58_22_57_94_74_36_22_65_95_79_40_14_62_36_94_58_31_92_15_66_44_85_58_92_52_100_91_76_82_55_86_41_59_71_94_79_36_9_3_84_96_97_9_12_34_73_94_52_86_25_98_25_45_61_47_100_0_18_91_0_100_81_94_8_6_10_100_26_68_45_45_21_11',
//       'genes_29_73_29_27_100_88_91_7_97_34_86_100_69_33_85_49_44_25_68_81_76_64_12_51_36_37_60_43_30_42_7_79_100_91_51_100_27_80_87_85_92_22_30_85_56_35_10_58_87_33_46_74_36_22_17_95_79_90_79_62_23_82_58_16_29_18_30_87_80_58_21_90_100_39_12_82_51_100_41_58_16_16_85_72_46_16_88_55_87_9_14_66_77_4_51_11_69_95_25_49_61_47_96_0_62_50_92_91_44_14_29_6_41_100_4_49_61_87_21_68',
//       'genes_40_17_46_38_62_15_92_35_92_41_81_56_100_9_15_38_5_74_0_75_67_47_65_47_73_71_59_25_26_33_2_28_100_90_62_100_83_82_19_37_28_47_61_71_63_81_9_16_78_23_54_44_32_65_75_78_79_85_98_27_41_72_67_3_37_5_25_20_75_57_29_17_100_18_17_37_58_56_16_29_37_100_96_5_4_6_35_87_73_40_31_60_9_61_100_21_39_100_25_59_18_14_4_74_84_100_1_90_76_79_8_82_33_100_27_64_61_64_18_15',
//       'genes_100_50_46_41_62_16_26_18_80_41_62_56_75_12_70_38_5_21_76_57_18_39_12_6_59_71_88_25_30_70_15_29_100_80_95_7_32_82_36_78_28_86_19_99_55_76_9_16_78_74_61_78_92_57_75_21_78_44_100_27_41_75_35_14_32_2_26_65_27_67_29_17_100_28_54_37_58_52_23_10_37_94_96_45_4_6_85_55_70_16_14_23_25_1_81_20_27_43_90_57_73_39_87_39_44_35_0_100_41_75_78_88_84_100_27_11_64_69_19_18',
//       'genes_34_42_69_65_75_44_98_91_60_60_27_60_62_27_12_52_58_74_76_61_75_15_81_73_85_70_21_45_90_29_64_58_100_82_77_40_30_77_10_74_57_9_81_96_89_22_4_19_12_4_43_48_84_84_35_90_97_54_100_31_39_100_62_98_49_83_25_4_75_51_33_55_100_79_79_95_31_51_16_37_91_14_76_62_16_1_39_1_82_36_6_5_72_94_45_21_100_100_19_80_11_4_66_4_78_45_43_13_86_82_88_0_40_100_46_35_9_60_13_15',
//       'genes_98_29_2_60_16_51_4_49_47_29_81_52_4_21_82_57_22_98_32_41_85_47_0_42_39_81_25_44_0_18_27_50_100_92_48_96_15_33_11_78_9_69_87_96_67_13_4_83_53_67_59_28_83_39_18_16_4_46_93_18_54_75_3_48_36_22_30_59_46_43_47_16_100_97_55_82_55_54_68_29_38_100_1_2_18_4_78_4_66_16_77_5_78_6_5_24_94_56_58_87_80_72_64_50_50_20_91_30_57_82_8_92_84_100_21_44_62_87_32_67',
//       'genes_77_18_20_64_0_53_92_35_97_27_95_60_66_44_68_54_21_5_89_40_38_19_79_42_59_82_45_9_89_64_14_45_100_79_14_59_73_16_13_31_81_89_60_69_84_65_0_69_58_64_43_64_82_57_75_25_100_29_41_11_39_68_60_38_25_15_25_4_29_61_8_93_100_28_13_75_3_51_54_37_42_53_74_7_86_6_43_15_8_51_48_78_93_56_52_21_31_100_55_90_35_44_63_0_70_92_39_99_69_83_5_100_85_100_68_46_45_87_26_68',
//       'genes_100_9_72_27_70_12_54_22_92_17_86_47_68_10_19_0_36_98_68_38_37_89_79_17_58_68_47_55_81_70_65_97_100_91_86_99_32_36_41_97_100_76_30_88_77_76_15_59_99_43_93_54_91_41_19_29_74_85_100_27_63_100_54_78_87_19_0_86_100_58_36_52_100_35_55_95_67_18_68_18_65_100_70_62_23_8_52_90_66_93_7_79_94_42_97_21_59_63_25_75_36_6_24_66_44_34_90_64_38_52_44_8_74_100_25_70_62_98_79_64',
//       'genes_61_65_88_27_70_79_81_77_29_49_84_36_72_87_82_25_60_21_30_39_6_26_79_70_16_50_54_86_63_51_0_29_100_80_46_50_62_39_43_90_86_32_14_99_79_61_9_83_64_59_29_63_83_20_26_16_0_84_43_26_31_10_67_48_33_51_25_99_45_55_96_45_100_72_51_75_54_85_24_37_13_100_29_44_98_33_88_8_41_61_98_100_80_1_53_24_8_20_63_100_79_50_21_15_100_15_23_45_86_94_95_0_62_100_68_52_46_41_13_69',
//       'genes_40_16_18_51_70_14_50_23_92_28_78_47_72_39_90_42_59_98_90_86_61_18_80_60_60_53_11_48_85_70_47_57_100_15_54_7_45_28_12_17_100_29_1_0_68_45_15_59_40_63_75_70_82_22_35_27_77_42_47_19_39_82_62_9_47_1_7_9_82_4_88_54_100_53_10_79_33_25_83_96_16_87_88_45_5_3_85_51_8_77_99_74_49_23_51_18_70_95_19_90_73_95_73_0_85_79_5_28_43_52_20_60_62_100_61_67_62_39_28_34',
//       'genes_10_16_6_60_77_47_42_34_27_71_88_61_78_24_56_52_22_78_84_38_46_38_47_40_59_56_44_53_70_14_43_29_100_65_10_48_74_4_30_4_93_69_14_53_79_43_37_53_46_85_76_72_94_60_89_81_3_40_42_34_28_96_40_52_13_76_31_4_69_52_4_77_100_97_20_33_66_52_14_10_67_20_58_45_23_6_15_76_73_66_93_5_71_79_11_24_100_0_18_96_35_34_76_49_94_46_42_98_46_68_19_92_10_100_29_46_64_33_33_50',
//       'genes_14_8_6_60_40_79_52_21_81_23_29_3_29_94_50_54_44_74_66_10_80_46_16_39_64_98_56_64_85_64_2_46_100_89_14_48_21_82_30_90_38_74_10_85_24_30_10_80_89_33_30_15_90_67_26_90_23_86_96_55_35_6_29_100_28_100_27_47_99_3_96_52_100_37_11_10_98_97_56_41_14_100_74_58_58_5_85_54_73_2_100_32_77_94_55_26_28_49_59_49_78_45_30_50_86_39_50_21_86_94_95_45_84_100_61_93_51_69_82_69',
//       'genes_61_30_62_27_99_72_87_35_84_28_86_88_62_10_82_54_76_66_45_10_32_39_72_91_42_54_59_19_27_69_83_29_100_75_78_47_33_80_57_79_100_0_54_74_56_47_98_20_53_3_73_60_22_32_65_10_24_43_98_31_30_73_54_81_22_22_29_44_85_43_23_92_100_35_79_42_53_18_69_43_29_10_79_37_0_3_58_96_66_36_100_34_51_94_5_86_94_93_55_49_30_72_93_0_61_91_47_98_80_94_25_4_30_100_4_28_45_63_88_11',
//       'genes_100_29_20_56_62_11_82_36_37_10_82_95_32_10_20_57_22_21_0_57_18_38_70_51_62_70_39_23_2_14_15_29_100_80_9_91_59_75_22_29_83_56_34_67_59_76_4_53_78_82_61_28_95_39_75_84_1_39_14_15_16_91_62_7_97_6_30_10_12_67_23_97_100_28_79_37_53_51_23_10_67_90_8_45_12_6_85_81_73_57_14_72_63_1_28_20_27_41_56_100_80_35_70_50_71_60_73_89_80_47_14_4_72_100_28_50_64_69_32_16',
//       'genes_10_8_68_93_68_63_66_60_97_71_3_97_65_94_70_61_1_74_100_75_71_41_14_56_14_64_25_20_63_33_60_82_100_83_71_67_21_2_80_95_96_96_11_56_68_66_10_80_50_25_75_63_60_96_17_52_11_31_58_55_38_75_19_100_44_7_29_84_4_36_37_54_100_66_93_80_98_51_5_96_68_64_96_40_7_2_83_83_82_40_27_98_77_79_52_67_48_17_59_100_17_43_14_2_39_13_41_98_92_30_21_82_10_100_61_82_13_50_32_55',
//       'genes_61_8_72_11_40_79_22_63_11_17_83_97_65_42_70_38_95_77_1_95_71_41_79_66_88_56_25_20_63_29_100_84_100_8_88_39_33_80_58_95_25_69_1_88_66_69_0_17_89_25_29_55_57_67_18_65_99_31_57_55_38_97_18_100_33_10_5_86_30_31_52_54_100_16_59_27_63_61_56_53_73_66_75_70_57_12_85_83_82_7_10_74_77_78_46_24_43_63_24_18_1_45_62_5_42_35_36_24_3_52_21_82_71_100_61_51_48_13_52_99',
//       'genes_57_42_62_7_61_12_92_22_88_27_49_17_62_27_12_87_72_74_60_50_36_66_81_43_85_9_21_48_8_29_56_58_100_63_93_40_58_77_33_27_72_38_86_17_84_22_18_74_73_68_43_59_96_61_68_90_24_85_60_19_42_72_62_98_8_0_46_14_75_8_12_92_100_79_76_35_29_51_56_87_91_14_23_38_16_12_40_2_11_36_7_1_72_7_18_24_100_0_19_80_24_14_66_5_15_45_43_93_47_83_83_3_40_100_20_40_46_60_74_15',
//       'genes_25_15_55_50_77_51_26_34_95_71_59_25_68_24_17_43_22_21_4_13_79_97_42_61_59_9_9_16_51_68_66_81_100_83_75_43_66_4_29_29_41_69_75_96_79_79_2_78_46_29_29_67_84_60_19_47_3_40_98_74_22_94_52_48_99_2_27_4_85_47_42_90_100_97_81_77_70_15_23_21_70_100_58_29_23_4_17_76_66_66_92_52_20_1_59_49_100_21_78_96_35_34_43_0_91_44_94_96_46_68_19_62_19_100_4_46_41_63_33_31',
//       'genes_35_25_18_50_70_11_37_94_11_12_85_56_99_87_85_87_31_5_23_55_84_19_98_42_59_99_61_49_66_68_93_50_100_15_50_92_32_82_11_97_40_74_60_92_74_42_9_59_78_9_28_75_96_60_23_16_53_71_97_19_28_77_54_5_87_29_32_89_68_4_14_97_100_24_78_73_46_52_16_44_67_0_4_72_15_4_58_6_73_57_61_99_71_30_46_26_27_41_18_47_67_5_30_7_34_49_22_28_29_57_9_92_9_100_61_79_53_36_26_22',
//       'genes_11_21_88_49_62_80_59_94_49_93_93_61_43_24_76_52_60_93_30_61_84_97_98_70_59_6_54_22_66_95_98_33_100_16_92_28_33_82_24_29_11_29_63_21_74_66_15_59_54_77_37_54_84_60_27_30_59_36_98_19_36_94_58_7_87_28_31_61_69_70_37_52_100_24_76_73_55_100_42_87_46_90_24_32_86_9_34_45_73_87_98_93_60_30_24_1_13_20_59_36_76_95_0_51_39_96_19_87_85_82_8_0_9_100_65_64_46_37_26_71',
//       'genes_10_17_49_54_41_82_85_63_81_69_84_49_99_42_80_56_95_66_32_95_59_41_16_66_56_56_26_23_81_64_22_46_100_90_46_39_33_82_89_90_26_74_1_88_24_30_9_79_78_64_43_59_57_67_26_90_99_86_61_27_35_97_18_48_38_8_78_86_30_55_98_52_100_16_51_77_63_25_72_43_23_64_76_70_58_2_85_30_66_40_100_32_78_35_55_24_20_63_58_18_16_68_63_5_61_35_49_33_86_94_9_1_71_100_25_46_46_69_52_27',
//       'genes_98_50_66_46_23_47_50_21_53_13_83_97_87_66_85_38_51_21_59_56_84_39_80_47_85_60_11_19_26_51_76_82_100_80_65_92_29_17_40_73_96_23_75_88_46_47_0_83_44_88_73_77_83_57_23_21_0_79_97_27_55_75_53_4_44_76_33_65_1_48_8_54_100_29_67_77_66_85_14_39_37_100_88_43_29_11_12_58_42_16_6_50_53_4_96_60_31_96_23_18_65_7_8_0_43_35_46_25_86_75_21_93_62_100_24_41_14_69_68_31',
//       'genes_7_65_43_50_3_53_81_71_50_13_84_23_72_49_82_63_55_18_89_13_54_15_79_45_0_37_41_86_25_51_66_45_100_80_63_28_29_7_43_50_93_61_14_71_79_67_9_78_91_48_72_63_90_65_38_16_0_84_98_27_30_75_67_31_44_18_25_19_85_60_8_93_100_32_13_75_57_98_18_39_84_100_49_45_9_6_52_28_52_37_10_97_80_4_53_16_33_100_68_96_21_17_21_0_91_13_23_45_76_49_83_92_62_100_68_42_41_88_20_16',
//       'genes_89_12_88_90_69_50_89_41_97_37_85_14_81_13_81_0_60_23_30_96_76_28_46_70_72_50_54_39_96_98_55_29_100_83_45_100_28_3_14_87_41_87_10_62_63_98_9_83_12_26_27_59_55_50_26_25_8_41_100_74_40_10_62_96_26_51_48_100_73_64_36_52_100_15_54_83_72_100_24_93_66_93_79_37_62_28_88_17_41_3_31_75_69_76_53_24_8_20_68_30_87_16_28_25_100_60_22_99_92_30_21_2_40_100_25_26_46_41_26_69',
//       'genes_57_32_63_66_100_53_50_70_92_25_61_52_32_71_83_77_44_100_1_61_28_38_83_51_75_43_50_55_13_30_90_3_100_63_90_79_33_40_6_79_70_30_43_57_77_37_4_22_89_67_70_56_87_39_24_9_60_48_57_26_16_79_65_12_33_6_33_85_5_78_23_94_100_24_70_32_73_17_44_90_59_86_71_17_12_3_5_11_5_58_100_100_97_1_52_73_12_91_7_18_94_84_25_24_95_59_46_54_80_85_29_4_42_100_64_16_62_84_49_58',
//       'genes_57_15_24_26_61_24_93_91_43_37_78_58_39_73_80_34_27_4_31_61_83_39_33_4_25_65_21_52_85_69_55_27_100_43_86_46_73_81_61_82_25_1_78_17_82_17_4_16_48_80_24_28_55_21_28_42_2_82_88_62_19_6_65_78_30_0_27_85_64_66_9_60_100_22_54_72_72_56_19_35_69_90_100_48_58_3_37_11_87_56_94_30_50_33_75_74_80_92_52_30_88_56_25_48_100_32_49_56_9_77_25_92_24_100_61_88_60_14_88_59',
//       'genes_61_90_10_58_0_55_92_49_93_79_81_3_95_51_85_57_58_68_32_92_28_38_5_43_58_71_25_19_67_8_99_46_100_68_66_96_73_27_89_12_63_84_60_96_67_44_3_83_98_65_72_59_88_58_18_2_0_33_100_17_39_79_3_7_36_6_30_14_100_15_29_96_100_66_46_65_98_66_65_39_71_86_91_17_53_3_40_6_5_67_100_52_75_61_52_22_5_100_18_87_16_66_66_5_95_100_44_25_73_55_88_5_33_100_5_93_50_26_27_58',
//       'genes_10_96_15_50_68_63_9_60_97_71_84_85_62_70_17_61_58_70_32_63_75_98_69_45_59_51_25_21_67_39_63_30_100_31_75_100_92_2_29_95_96_8_14_17_67_30_99_78_91_69_72_82_36_84_19_90_21_40_96_19_95_75_96_77_33_7_25_94_81_47_39_93_100_24_93_77_24_98_5_36_65_67_59_5_7_3_83_81_52_83_10_98_13_76_20_67_48_13_19_100_17_17_63_18_39_39_41_23_92_30_83_82_19_100_24_46_50_88_32_55',
//       'genes_100_90_37_90_67_60_54_49_37_34_81_56_84_9_80_57_36_98_5_56_3_72_81_47_60_34_25_48_30_18_3_97_100_91_93_96_15_82_57_78_97_47_1_17_77_42_5_51_98_64_72_56_87_25_21_16_79_67_96_12_41_97_13_85_72_6_7_86_46_14_41_16_100_97_55_75_55_18_68_43_69_100_91_13_18_4_2_1_73_19_14_70_94_52_51_24_8_21_58_75_36_95_66_4_38_75_93_17_23_58_8_47_84_100_21_51_45_35_33_69',
//       'genes_100_85_37_90_70_60_91_52_37_69_85_14_84_100_81_36_50_98_91_58_76_39_100_47_67_34_67_98_71_33_5_97_100_24_39_36_48_34_50_29_94_90_73_17_63_43_18_87_96_21_75_59_83_25_24_25_79_85_64_21_10_50_60_78_21_1_29_86_77_73_26_74_100_63_54_75_51_56_25_43_69_88_75_13_21_3_2_83_70_4_94_70_94_52_85_21_8_100_25_75_36_76_22_51_44_62_47_61_20_1_9_8_28_100_94_51_62_64_13_23',
//       'genes_34_78_62_62_70_67_52_91_57_33_27_28_48_20_35_52_58_87_79_38_75_18_38_70_22_70_61_46_66_64_64_86_100_15_78_14_30_89_12_74_9_68_48_84_89_71_4_19_42_60_36_49_82_84_92_49_97_71_57_19_55_100_57_9_47_22_30_78_76_3_33_48_100_26_6_75_72_83_56_37_69_100_76_62_9_1_86_57_73_82_99_43_13_79_45_1_80_43_19_25_76_59_9_0_34_50_36_18_86_56_95_92_40_100_61_59_60_55_26_11',
//       'genes_100_8_48_93_40_56_80_50_11_5_81_97_75_94_84_38_5_21_3_51_71_57_12_56_88_60_50_20_22_33_44_82_100_83_71_69_21_79_48_87_89_96_11_56_46_69_0_95_55_27_75_55_60_67_23_82_11_33_100_23_38_7_42_85_28_10_29_78_82_27_52_54_100_64_53_35_98_61_24_95_13_66_75_48_1_13_56_18_73_3_31_74_77_24_52_3_5_97_59_98_1_61_44_2_86_51_30_92_3_82_21_52_11_100_61_26_9_67_82_69',
//       'genes_58_16_37_65_83_53_54_7_11_23_29_3_27_94_58_44_20_72_64_43_80_97_21_41_59_64_82_10_87_31_93_18_100_91_92_66_48_81_60_95_30_69_80_64_79_30_17_17_54_25_46_76_82_22_20_49_23_35_86_87_45_6_16_100_8_100_28_82_19_59_49_100_100_31_54_84_98_94_56_41_16_91_74_64_68_53_86_54_63_7_33_64_77_89_57_83_13_41_71_49_95_39_30_61_86_60_48_20_86_19_95_45_62_100_57_60_45_13_31_71',
//       'genes_61_4_43_56_40_79_25_63_41_17_50_49_72_42_83_56_95_72_31_95_32_45_73_66_52_51_25_53_81_33_22_75_100_3_56_34_33_87_80_29_25_63_1_4_78_39_11_83_50_2_61_63_28_67_24_46_99_37_57_54_41_97_18_4_37_10_28_86_30_55_21_52_100_31_54_77_57_55_72_43_63_27_79_70_71_48_85_37_49_95_12_32_0_62_23_21_83_19_21_18_40_48_4_25_20_35_7_66_86_42_9_2_20_100_25_26_48_71_52_31',
//       'genes_81_73_62_22_70_79_52_51_57_28_86_28_71_20_19_57_25_84_7_96_84_18_65_70_67_6_47_4_66_64_45_46_100_15_88_40_74_5_27_31_35_91_74_5_65_38_15_69_42_39_25_52_82_57_70_25_79_71_70_22_20_30_57_9_45_56_80_88_12_22_72_54_100_62_10_79_10_51_36_43_69_100_73_64_5_6_21_59_9_52_96_98_62_31_90_10_8_59_29_23_73_66_24_2_100_33_43_92_40_88_95_60_44_100_61_59_45_58_27_55',
//       'genes_95_60_37_56_97_44_21_67_88_39_97_78_31_29_84_13_50_72_90_96_32_18_98_55_85_60_56_31_88_68_4_79_100_88_50_36_25_78_10_97_5_90_65_57_58_38_0_87_96_85_31_41_87_53_20_31_82_38_90_19_71_80_21_96_28_20_34_86_18_48_72_95_100_66_54_82_69_0_15_87_71_100_43_61_16_13_80_32_87_0_99_50_67_25_51_10_33_43_19_15_73_34_33_98_43_60_82_27_35_78_95_55_10_100_55_93_37_55_81_59',
//       'genes_61_12_66_46_69_16_49_49_29_23_81_14_76_65_81_38_50_21_30_57_89_7_78_47_52_50_56_19_26_18_17_36_100_80_46_92_58_12_17_93_41_30_85_100_79_55_9_83_16_88_73_59_85_22_52_21_0_82_100_23_5_7_53_48_28_76_33_65_82_48_67_59_100_29_51_79_72_93_24_37_64_90_29_44_29_30_15_58_41_25_14_32_73_95_96_60_84_100_25_18_80_16_17_5_71_35_22_25_40_79_95_0_62_100_64_26_45_39_68_31',
//       'genes_58_50_54_52_52_93_54_60_97_56_7_59_31_51_84_57_52_65_27_52_64_51_16_98_58_82_60_48_76_44_2_28_100_94_80_14_85_7_78_29_93_74_87_100_61_48_9_86_53_76_43_45_92_60_20_89_53_37_92_22_74_50_9_4_38_20_78_97_50_57_46_50_100_24_93_80_36_51_72_93_35_64_79_41_6_3_15_100_76_35_3_98_75_53_9_21_48_85_59_56_17_34_24_98_20_55_45_66_89_79_0_82_33_100_4_26_48_60_22_55',
//       'genes_61_67_22_91_40_79_25_22_92_17_49_49_65_42_77_56_59_21_31_61_61_18_79_66_87_49_25_27_81_70_18_78_100_91_83_39_33_28_59_17_52_47_1_88_46_69_1_59_78_64_64_59_82_67_74_16_82_48_47_13_41_21_18_67_87_80_7_86_82_73_8_10_100_53_69_77_63_25_72_43_16_87_76_13_57_48_85_30_8_40_12_36_63_81_48_21_20_63_24_30_11_3_62_0_39_35_49_30_86_52_9_1_67_100_25_67_48_75_33_27',
//       'genes_58_21_46_27_43_56_94_55_83_41_89_56_66_14_81_21_60_21_25_56_6_26_14_44_59_72_54_24_27_69_60_28_100_92_40_59_58_91_19_78_25_30_2_100_67_89_10_81_54_64_30_44_83_65_28_90_0_67_99_15_39_94_33_48_28_51_25_19_72_73_29_48_100_30_13_81_60_52_63_77_91_90_35_5_2_3_88_8_46_9_10_32_57_56_49_24_100_100_55_57_79_16_44_79_100_15_87_12_86_94_95_0_40_100_25_46_46_58_26_69',
//       'genes_40_16_46_42_62_14_84_77_86_28_78_54_77_39_70_38_52_74_81_60_18_24_0_6_60_71_88_55_47_69_47_62_100_15_95_43_75_99_19_31_43_77_62_66_67_43_9_16_40_23_25_44_82_65_70_29_78_71_99_19_65_50_35_13_47_0_2_20_37_4_29_54_100_23_10_35_58_52_16_80_37_94_40_5_5_6_56_55_82_16_31_60_9_27_81_73_39_43_94_55_73_14_73_39_85_63_41_28_40_60_21_60_10_100_27_12_61_69_19_44',
//       'genes_40_21_62_7_62_80_59_47_100_28_58_28_73_42_76_12_60_93_7_38_29_18_88_44_61_6_11_10_66_95_73_29_100_17_93_96_14_89_96_31_11_29_48_84_64_62_15_69_54_77_25_44_87_21_27_18_53_71_57_6_22_72_57_12_29_1_2_18_100_3_41_52_100_14_12_42_54_97_42_43_36_100_75_64_58_53_85_58_87_87_99_48_60_39_90_1_12_20_59_23_69_72_44_0_24_98_19_17_73_56_8_0_40_100_65_69_43_58_31_71',
//       'genes_51_39_18_58_43_79_93_52_48_15_81_10_62_73_81_65_50_94_33_97_39_66_73_56_83_71_21_32_92_72_55_53_100_92_48_42_28_77_10_31_97_47_1_86_60_98_18_76_89_15_19_63_84_62_72_63_69_82_97_23_41_53_67_80_3_4_25_60_75_56_26_55_100_77_16_77_31_25_32_66_14_21_1_34_57_3_89_79_87_16_100_24_52_94_95_22_29_56_96_29_86_14_22_79_94_26_27_97_9_55_55_8_8_100_20_39_62_29_68_11',
//       'genes_41_42_69_14_43_34_94_22_76_28_78_60_70_23_82_69_72_84_60_52_67_61_85_46_46_6_59_44_13_70_96_44_100_82_88_100_22_77_37_79_25_59_54_72_56_33_9_80_54_25_43_48_83_63_29_88_24_85_93_19_39_20_96_81_29_14_25_6_75_43_8_93_100_35_11_35_29_97_16_77_82_14_29_32_72_11_58_2_5_0_11_0_72_56_18_21_100_97_56_80_73_14_66_91_38_64_47_92_7_83_20_2_36_100_9_50_9_45_19_15',
//       'genes_98_67_33_65_43_12_94_22_74_23_78_16_69_5_12_47_22_25_68_61_78_65_81_47_30_37_60_48_59_96_7_58_100_82_50_100_52_86_89_97_67_23_81_89_40_22_0_58_53_57_49_72_36_63_34_95_79_85_100_62_39_99_58_98_87_15_34_82_80_61_12_93_100_42_76_35_29_86_16_54_71_10_23_32_46_16_84_2_87_39_6_70_72_94_18_21_100_10_19_80_61_47_96_4_19_45_0_100_42_83_10_6_40_100_20_40_61_57_16_15',
//       'genes_57_4_37_56_97_87_50_70_92_39_88_52_32_45_71_52_80_100_0_50_78_38_83_51_85_37_50_48_88_25_98_31_100_63_93_81_30_67_6_39_5_90_43_57_56_30_0_22_73_20_70_28_87_53_20_84_82_64_89_26_16_79_14_12_47_0_34_66_82_48_71_95_100_66_70_51_73_86_15_86_66_100_24_61_72_3_84_11_5_0_100_100_97_70_52_10_27_43_19_98_73_81_13_2_90_60_43_98_35_16_96_55_42_100_57_16_61_7_52_58',
//       'genes_9_39_63_11_62_53_84_41_93_30_26_56_46_71_14_39_42_74_28_64_28_73_14_47_85_68_50_48_13_60_90_3_100_93_48_44_73_40_9_84_70_30_14_59_59_22_4_5_89_8_70_56_92_72_68_9_80_67_60_15_43_18_65_12_33_2_33_25_74_55_29_93_100_14_5_33_69_17_56_42_48_78_45_43_4_6_61_11_7_57_90_66_59_1_6_24_22_100_25_18_50_81_87_22_44_18_43_93_46_85_8_3_38_100_2_51_46_87_33_58',
//       'genes_41_9_72_14_14_34_58_22_83_17_89_47_73_42_80_69_94_98_61_52_67_85_80_47_60_59_47_56_81_33_22_18_100_95_84_36_33_36_59_79_25_59_1_77_56_76_15_59_87_67_92_26_83_67_24_82_79_33_97_30_40_97_54_64_18_80_5_94_82_43_8_52_100_35_11_78_67_97_32_80_37_100_29_48_51_13_58_62_66_93_7_66_22_56_97_21_35_63_25_30_73_6_91_66_44_63_90_65_38_82_20_9_40_100_9_50_3_45_19_27',
//       'genes_58_80_62_9_69_12_46_22_88_26_84_14_76_13_81_63_60_68_30_58_4_26_0_70_72_9_50_53_96_69_48_56_100_63_93_78_58_39_33_31_41_38_14_99_79_22_18_74_73_68_29_59_83_22_26_99_0_82_57_25_40_72_33_98_33_0_48_14_99_0_25_93_100_30_77_88_72_19_56_37_13_26_18_44_1_30_88_11_41_2_100_32_73_0_53_24_8_21_68_28_79_14_44_5_100_40_47_93_40_55_95_0_40_100_25_26_46_41_74_69',
//       'genes_57_85_11_91_97_88_92_22_92_9_45_47_72_51_56_38_39_68_9_61_61_38_80_43_87_49_53_55_71_8_45_41_100_91_19_7_42_27_59_13_63_84_1_57_56_8_26_83_86_63_72_56_86_88_35_2_0_81_47_68_39_41_62_62_40_63_30_48_78_73_47_96_100_66_73_19_73_63_67_96_71_97_23_17_57_3_85_10_9_72_98_52_94_1_51_21_53_95_27_87_39_76_62_5_35_18_90_88_38_52_21_0_62_100_5_49_46_79_29_34',
//       'genes_100_83_37_90_70_60_94_21_92_67_81_47_84_9_56_40_96_98_0_58_27_42_65_52_60_30_62_48_76_33_5_97_100_91_50_72_48_35_57_34_97_47_1_17_42_77_18_81_78_21_54_77_87_46_24_30_79_85_100_35_39_73_13_4_37_8_7_86_48_57_47_74_100_59_55_75_52_18_14_69_38_100_76_5_88_8_36_87_73_40_12_23_76_52_56_21_27_100_25_57_18_76_4_79_44_79_5_93_76_1_17_2_33_100_17_51_62_60_81_57',
//       'genes_98_28_15_66_16_53_94_70_37_29_86_10_32_10_82_0_39_21_85_40_54_69_81_58_42_71_61_44_27_29_5_98_100_92_8_28_50_35_29_26_37_84_60_14_56_13_8_78_84_21_29_28_83_64_17_47_0_43_98_74_30_96_96_48_99_83_30_86_75_16_42_93_100_58_55_82_33_69_2_77_64_18_1_37_21_6_4_90_49_88_88_74_57_89_54_49_11_56_89_87_16_72_4_29_30_20_47_97_74_82_84_2_25_100_22_51_62_98_38_68',
//       'genes_61_65_100_58_62_79_81_77_29_55_89_54_72_87_82_65_65_67_89_39_45_15_96_1_75_78_30_9_63_44_2_34_100_85_63_100_66_35_43_50_9_89_70_71_67_61_9_87_96_36_73_78_86_60_38_16_0_84_43_27_36_75_67_14_36_20_25_4_100_4_5_52_100_72_13_16_59_52_18_29_38_10_54_5_9_1_43_92_13_37_98_100_78_53_53_2_32_100_63_100_33_50_21_10_39_30_95_45_86_94_5_92_62_100_65_64_60_74_23_11',
//       'genes_61_60_72_10_40_79_25_63_11_13_85_12_65_42_81_56_50_26_31_95_76_39_100_66_56_65_25_98_81_33_55_78_100_26_88_43_33_40_47_28_98_88_0_88_66_43_0_87_96_10_23_59_61_67_74_16_6_45_78_27_41_46_18_80_18_1_5_6_32_9_26_52_100_16_54_76_63_56_29_43_67_94_77_35_57_3_61_83_66_40_94_75_53_89_46_21_33_20_24_17_72_50_22_51_94_35_49_28_86_75_9_1_71_100_22_51_64_64_13_19',
//       'genes_40_60_69_7_61_12_21_22_23_26_95_87_62_29_84_63_48_68_32_50_36_66_0_43_85_9_61_31_8_99_46_46_100_86_93_81_58_89_48_31_40_29_68_14_59_22_18_87_73_68_73_59_87_21_24_90_60_85_57_20_71_72_21_98_38_0_25_67_75_4_29_95_100_24_77_32_76_0_56_89_71_14_71_34_16_9_40_32_8_36_6_1_97_24_9_24_12_100_22_95_73_14_0_98_43_55_93_95_46_78_9_3_69_100_90_11_65_55_74_58',
//       'genes_57_39_51_67_67_87_19_67_92_25_81_52_32_10_85_59_52_98_0_50_3_41_0_42_72_76_50_25_0_18_98_31_100_69_48_96_15_82_11_79_70_59_43_57_82_42_4_22_98_64_73_54_87_39_17_19_1_44_54_13_41_79_67_9_33_0_32_52_46_78_41_19_100_97_55_51_55_54_49_36_66_86_86_2_18_9_78_11_73_94_46_5_97_6_60_49_10_91_58_36_80_95_66_50_35_59_88_98_23_16_29_4_42_100_24_93_62_84_32_11',
//       'genes_41_39_72_11_40_79_93_68_92_28_83_10_70_42_85_56_95_54_31_95_62_41_79_47_56_9_21_27_81_69_22_78_100_80_88_42_71_82_80_31_30_56_1_88_59_24_0_35_77_64_67_59_57_67_61_18_99_89_57_27_41_97_18_64_33_83_25_86_30_55_93_16_100_81_40_82_63_25_72_66_11_14_33_62_57_48_85_57_8_36_12_19_63_81_46_21_75_63_24_30_15_22_62_4_39_35_50_89_86_52_88_42_71_100_47_40_51_29_68_62',
//       'genes_9_60_20_2_62_60_84_24_85_27_73_56_62_25_83_39_5_98_29_94_27_66_14_44_72_14_21_48_22_67_46_49_100_92_10_36_73_77_10_73_87_56_35_66_67_43_9_30_96_91_31_44_65_64_68_90_90_67_88_27_43_50_96_77_8_1_27_78_32_56_29_93_100_12_25_15_72_57_15_42_48_78_81_43_10_6_61_62_80_24_7_0_70_89_6_43_27_90_19_62_73_14_87_22_43_60_50_93_43_55_9_3_96_100_20_66_61_79_13_85',
//       'genes_100_50_55_56_71_79_54_94_37_22_83_97_62_42_82_40_24_75_84_75_85_98_73_17_59_72_64_20_95_95_11_80_100_65_88_12_25_18_78_31_97_69_19_88_77_34_2_5_86_9_26_78_82_19_19_13_74_40_47_31_37_75_56_96_87_2_33_11_75_55_76_10_100_97_43_23_51_56_5_43_92_21_1_41_6_9_19_83_9_19_22_50_95_1_24_21_9_2_56_100_17_39_1_98_36_50_0_27_46_69_16_66_10_100_19_61_64_98_33_52',
//       'genes_58_11_15_65_64_37_52_75_97_72_16_28_43_70_17_3_55_18_39_13_54_71_69_45_59_65_41_21_90_65_0_29_100_2_36_25_9_18_35_29_40_62_18_17_79_67_99_63_91_10_72_82_37_76_19_90_21_40_62_69_57_85_58_75_44_80_35_83_7_52_44_93_100_32_70_56_57_100_14_81_69_100_25_7_51_6_63_6_73_83_10_100_80_17_0_76_28_21_91_96_21_17_66_60_25_96_47_93_78_55_83_4_45_100_34_42_41_58_6_71',
//       'genes_100_78_33_0_100_40_92_100_44_26_86_47_62_36_19_5_36_8_68_38_37_63_96_56_22_60_60_55_90_67_5_37_100_43_48_39_59_52_78_97_97_65_58_14_61_79_12_30_99_82_72_54_85_84_57_12_62_63_100_18_87_4_8_78_26_73_30_9_100_54_49_90_100_26_42_95_57_18_68_41_36_100_100_55_23_8_15_90_37_93_12_79_77_75_100_96_8_98_91_67_26_24_24_0_18_39_38_17_20_52_33_9_24_100_17_29_70_13_79_64',
//       'genes_9_8_22_60_40_83_56_22_97_18_49_3_31_94_56_36_59_74_32_61_80_21_19_47_91_49_53_48_85_31_93_46_100_89_10_44_23_77_30_13_30_29_80_0_75_30_8_59_86_25_75_15_82_65_20_27_79_81_45_68_39_6_60_96_44_100_30_48_82_3_8_100_100_53_73_82_98_25_56_96_69_100_88_5_71_3_85_51_8_7_4_36_77_40_57_26_27_41_27_53_39_45_63_18_86_41_48_21_49_52_71_66_62_100_61_66_62_14_33_34',
//       'genes_59_39_51_60_70_79_4_52_40_37_85_49_4_73_85_56_22_94_32_96_3_41_0_38_72_76_29_28_9_69_55_50_100_69_48_96_15_82_17_78_9_50_1_96_60_44_9_67_98_10_73_59_84_50_29_16_0_82_60_13_41_75_67_85_72_23_78_87_78_13_26_16_100_97_55_43_67_25_32_38_65_91_100_62_62_4_78_79_75_16_12_23_78_6_5_22_79_21_58_36_80_3_66_50_94_36_93_30_9_62_50_8_84_100_21_84_45_87_32_11',
//     ];

//     final geneString = genes ??
//         randomChoice([
//           ...topAgents,
//           // bullyGenes
//         ], [
//           ...[for (int i = 0; i < topAgents.length; i++) 1 / (topAgents.length * 2)],
//           // 1 / 2
//         ])!;

//     final geneList = geneString.split('_');

//     for (var geneSetIndex = 0; geneSetIndex < numGeneCopies; geneSetIndex++) {
//       //+1 skips 'gene'
//       const numberOfGenes = NUMBER_OF_GENES;
//       final offset = numberOfGenes * geneSetIndex + 1;

//       final genes = Genes(
//         visualTrait: int.parse(geneList[0 + offset]),
//         homophily: int.parse(geneList[1 + offset]),
//         alpha: int.parse(geneList[2 + offset]),
//         otherishDebtLimits: int.parse(geneList[3 + offset]),
//         coalitionTarget: int.parse(geneList[4 + offset]),
//         // proportion of tokens to give out evenly in group_allocate
//         fixedUsage: int.parse(geneList[5 + offset]),
//         wModularity: int.parse(geneList[6 + offset]),
//         wCentrality: int.parse(geneList[7 + offset]),
//         wCollectiveStrength: int.parse(geneList[8 + offset]),
//         wFamiliarity: int.parse(geneList[9 + offset]),
//         wProsocial: int.parse(geneList[10 + offset]),
//         initialDefense: int.parse(geneList[11 + offset]),
//         minKeep: int.parse(geneList[12 + offset]),
//         defenseUpdate: int.parse(geneList[13 + offset]),
//         defensePropensity: int.parse(geneList[14 + offset]),
//         fearDefense: int.parse(geneList[15 + offset]),
//         safetyFirst: int.parse(geneList[16 + offset]),
//         pillageFury: int.parse(geneList[17 + offset]),
//         pillageDelay: int.parse(geneList[18 + offset]),
//         pillagePriority: int.parse(geneList[19 + offset]),
//         pillageMargin: int.parse(geneList[20 + offset]),
//         pillageCompanionship: int.parse(geneList[21 + offset]),
//         pillageFriends: int.parse(geneList[22 + offset]),
//         vengeanceMultiplier: int.parse(geneList[23 + offset]),
//         vengeanceMax: int.parse(geneList[24 + offset]),
//         vengeancePriority: int.parse(geneList[25 + offset]),
//         defendFriendMultiplier: int.parse(geneList[26 + offset]),
//         defendFriendMax: int.parse(geneList[27 + offset]),
//         defendFriendPriority: int.parse(geneList[28 + offset]),
//         attackGoodGuys: int.parse(geneList[29 + offset]),
//         limitingGive: int.parse(geneList[30 + offset]),
//         groupAware: int.parse(geneList[31 + offset]),
//         joinCoop: int.parse(geneList[32 + offset]),
//         trustRate: int.parse(geneList[33 + offset]),
//         distrustRate: int.parse(geneList[34 + offset]),
//         startingTrust: int.parse(geneList[35 + offset]),
//         wChatAgreement: int.parse(geneList[36 + offset]),
//         wTrust: int.parse(geneList[37 + offset]),
//         wAccusations: int.parse(geneList[38 + offset]),
//         fearAggression: int.parse(geneList[39 + offset]),
//         fearGrowth: int.parse(geneList[40 + offset]),
//         fearSize: int.parse(geneList[41 + offset]),
//         fearContagion: int.parse(geneList[42 + offset]),
//         fearThreshold: int.parse(geneList[43 + offset]),
//       );

//       genePools.add(genes);
//     }

//     if (geneString == bullyGenes) {
//       print('$myPlayerName is a bully');
//       genePools.first.printGenes();
//     }
//   }

//   void estimateKeeping(numPlayers, List<Set<String>> communities) {
//     keepingStrength = {};
//     final players = currentRound.info.playerPopularities.keys;
//     for (final player in players) {
//       // print('isKeeping for $player is ${isKeeping(player, players)}');
//       // print('fearKeeping for $player is ${fearKeeping(players, communities, player)}');
//       final keepingStrengthI =
//           max(isKeeping(player, players), fearKeeping(players, communities, player));
//       keepingStrength[player] = keepingStrengthI * currentRound.info.playerTokens;
//       print('keeping strength 1: $keepingStrengthI');
//     }
//   }

//   void computeUsefulQuantities() {
//     // print('computing quantities...');
//     final roundNum = currentRound.info.round;
//     final influences = transposeMap(removeIntrinsic(currentRound.info.playerInfluences));
//     if (roundNum > initialRound) {
//       inflNegPrev = inflNeg.map(MapEntry.new);
//     } else {
//       inflNegPrev = clipNegMatrix(influences);
//     }

//     inflPos = clipMatrix(influences);
//     inflNeg = clipNegMatrix(influences);

//     inflPosSumCol = sumOverAxis0(inflPos);
//     inflPosSumRow = sumOverAxis1(inflPos);

//     final players = influences.keys;
//     if (roundNum == initialRound) {
//       sumInflPos = {
//         for (final player1 in players) player1: {for (final player in players) player: 0.0}
//       };
//       attacksWithMe = {for (final player in players) player: 0.0};
//       othersAttackOn = {for (final player in players) player: 0.0};

//       inflictedDamageRatio = 1;
//       badGuys = {for (final player in players) player: 0.0};
//     } else {
//       sumInflPos = addMatrices(sumInflPos, inflPos);

//       const w = .2;

//       for (final player in players) {
//         var val = clipNegVector(influences.map((key, value) => MapEntry(
//             key,
//             value[player]! -
//                 (prevInfluence?[key]![player] ?? 0) *
//                     (1.0 - gameParams.popularityFunctionParams.alpha)))).values.sum;
//         final temp = (influences[myPlayerName]![player]! -
//                 (prevInfluence?[myPlayerName]![player]! ?? 0) *
//                     (1.0 - gameParams.popularityFunctionParams.alpha)) *
//             -1;
//         val -= temp > 0 ? temp : 0;
//         othersAttackOn[player] = othersAttackOn[player]! * w + (1 - w) * val;
//         if (player != myPlayerName) {
//           if ((prevAllocations?[player] ?? 0) < 0) {
//             final amount = clipNegVector(prevInfluence?.map((key, value) => MapEntry(
//                     key,
//                     influences[key]![player]! -
//                         value[player]! * (1.0 - gameParams.popularityFunctionParams.alpha))) ??
//                 {});
//             attacksWithMe = subtractVectors(attacksWithMe, amount);
//             if (expectedDefendFriendDamage != -99999) {
//               final newRatio = amount.values.sum / expectedDefendFriendDamage;
//               inflictedDamageRatio = .5 * inflictedDamageRatio + .5 * newRatio;
//             }
//           }
//         }
//       }
//       badGuys.updateAll((key, value) => value * (1 - gameParams.popularityFunctionParams.alpha));
//       final badGuysCopy = Map<String, double>.from(badGuys);
//       final clippedPrev = clipNegMatrix(prevInfluence ?? {});
//       final newSteals = inflNeg.map((key1, value) => MapEntry(
//           key1,
//           value.map((key2, value) => MapEntry(
//               key2,
//               value -
//                   (clippedPrev[key1]?[key2] ?? 0) *
//                       (1 - gameParams.popularityFunctionParams.alpha)))));
//       for (final i in players) {
//         for (final j in players) {
//           if (newSteals[i]![j]! > 5.0) {
//             if (badGuysCopy[j]! < 0.2) {
//               badGuys[i] = badGuys[i]! + newSteals[i]![j]! / 1.0;
//               if (badGuys[i]! > 1.0) {
//                 badGuys[i] = 1.0;
//               }
//             } else if (((inflNeg[j]!.values.sum) * 0.9) < (sumOverAxis0(inflNeg)[j]!)) {
//               badGuys[j] = 0;
//             }
//           }
//         }
//       }
//     }
//   }

//   Tuple2<List<Set<String>>, CommunityEvaluation> groupAnalysis() {
//     final players = currentRound.info.playerPopularities.keys.toSet();

//     if (currentRound.info.round == initialRound) {
//       final aPos = computeAdjacency();
//       final aNeg = computeNegAdjacency();

//       final result = louvainCMethodPhase1(players.length, aPos, aNeg);
//       final communitiesByIndex = result.first;
//       final communities = convertComFromIdx(communitiesByIndex, players.toList());

//       coalitionTarget = computeCoalitionTarget(communities);

//       final elijo = randomSelections(players, currentRound.info.playerPopularities);

//       // print('communities and elijo');
//       // print(communities);
//       // elijo.printCom();

//       return Tuple2(communities, elijo);
//     } else {
//       final aPos = computeAdjacency();
//       final aNeg = computeNegAdjacency();

//       final result = louvainCMethodPhase1(currentRound.info.groupMembers.length, aPos, aNeg);
//       final communitiesPh1 = result.first;
//       final modularityPh1 = result.second;

//       final result2 = louvainMethodPhase2(communitiesPh1, aPos, aNeg);
//       final communitiesMega = result2.first;
//       final modularity = result2.second;
//       final communitiesByIndex =
//           enumerateCommunity(modularityPh1, communitiesPh1, modularity, communitiesMega);

//       // print('Communities after Phase2');
//       // print(communitiesByIndex);

//       final communities = convertComFromIdx(communitiesByIndex, players.toList());
//       coalitionTarget = computeCoalitionTarget(communities);

//       final elijo = envisionCommunities(
//           aPos, aNeg, communitiesPh1, communitiesByIndex, communities, modularity);

//       // print('communities and elijo');
//       // print(communities);
//       // elijo.printCom();

//       return Tuple2(communities, elijo);
//     }
//   }

//   Map<String, Map<String, double>> computeAdjacency() {
//     final A = inflPos.map((key, value) => MapEntry(key, Map<String, double>.from(value)));
//     for (final player in currentRound.info.playerPopularities.keys) {
//       A[player]![player] = inflPos[player]![player]!;
//       for (final otherPlayer in currentRound.info.playerPopularities.keys
//           .toList()
//           .sublist(currentRound.info.playerPopularities.keys.toList().indexOf(player) + 1)) {
//         final theAve = (inflPos[player]![otherPlayer]! + inflPos[otherPlayer]![player]!) / 2;
//         final theMin = min(inflPos[player]![otherPlayer]!, inflPos[otherPlayer]![player]!);
//         A[player]![otherPlayer] = (theAve + theMin) / 2;
//         A[otherPlayer]![player] = A[player]![otherPlayer]!;
//       }
//     }
//     return A;
//   }

//   Map<String, Map<String, double>> computeNegAdjacency() {
//     final A = inflNeg.map((key, value) => MapEntry(key, Map<String, double>.from(value)));
//     for (final player in currentRound.info.playerPopularities.keys) {
//       A[player]![player] = inflNeg[player]![player]!;
//       for (final otherPlayer in currentRound.info.playerPopularities.keys
//           .toList()
//           .sublist(currentRound.info.playerPopularities.keys.toList().indexOf(player) + 1)) {
//         // final theAve = (inflNeg[player]![otherPlayer]! + inflNeg[otherPlayer]![player]!) / 2;
//         final theMax = max(inflNeg[player]![otherPlayer]!, inflNeg[otherPlayer]![player]!);
//         A[player]![otherPlayer] = theMax; //(theAve + theMax) / 2;
//         A[otherPlayer]![player] = A[player]![otherPlayer]!;
//       }
//     }

//     return A;
//   }

//   // phase1 using number input
//   Tuple2<List<Set<int>>, double> louvainCMethodPhase1(int numPlayers,
//       Map<String, Map<String, double>> aPos, Map<String, Map<String, double>> aNeg) {
//     final currentCommunities = List.generate(numPlayers, (index) => index);

//     if (numPlayers == 0) {
//       return const Tuple2([], 0);
//     }

//     final theGroups = List.generate(numPlayers, (index) => index).toSet();
//     var comMatrix = Matrix.identity(numPlayers);
//     final mPos = aPos.values
//         .fold(0.toDouble(), (previousValue, element) => previousValue + element.values.sum);
//     final kPos = sumOverAxis1(aPos);
//     final mNeg = aNeg.values
//         .fold(0.toDouble(), (previousValue, element) => previousValue + element.values.sum);
//     final kNeg = sumOverAxis1(aNeg);
//     var comCounts = Vector.filled(numPlayers, 1);
//     var hayCambio = true;

//     while (hayCambio) {
//       hayCambio = false;
//       for (var i = 0; i < numPlayers; i++) {
//         var mxCom = currentCommunities[i];
//         var bestDQ = 0.0;

//         for (final j in theGroups) {
//           if (currentCommunities[i] == j) {
//             continue;
//           }
//           final dQPos = moveItoJ(numPlayers, comMatrix, mPos, mapToVector(kPos), mapToMatrix(aPos),
//               i, j, currentCommunities[i]);

//           final dQNeg = moveItoJ(numPlayers, comMatrix, mNeg, mapToVector(kNeg), mapToMatrix(aNeg),
//               i, j, currentCommunities[i]);

//           final dQ = alpha * dQPos - (1 - alpha) * dQNeg;
//           if (dQ > bestDQ) {
//             mxCom = j;
//             bestDQ = dQ;
//           }
//         }
//         if (bestDQ > 0) {
//           comMatrix = setMatrixValue(comMatrix, currentCommunities[i], i, 0);
//           comCounts = setVectorValue(
//               comCounts, currentCommunities[i], comCounts[currentCommunities[i]] - 1);
//           if (comCounts[currentCommunities[i]] <= 0) {
//             theGroups.remove(currentCommunities[i]);
//           }
//           comMatrix = setMatrixValue(comMatrix, mxCom, i, 1);
//           comCounts = setVectorValue(comCounts, mxCom, comCounts[mxCom] + 1);
//           currentCommunities[i] = mxCom;
//           hayCambio = true;
//         }
//       }
//     }

//     final communities = <Set<int>>[];
//     for (var i = 0; i < numPlayers; i++) {
//       if (comCounts[i] > 0) {
//         final s = <int>{};
//         for (var j = 0; j < numPlayers; j++) {
//           if (comMatrix[i][j] == 1) {
//             s.add(j);
//           }
//         }
//         communities.add(s);
//       }
//     }

//     var theModularity =
//         alpha * computeModularity(numPlayers, currentCommunities, mapToMatrix(aPos));
//     theModularity -=
//         (1 - alpha) * computeModularity(numPlayers, currentCommunities, mapToMatrix(aNeg));

//     // print('communities');
//     // print(communities);
//     // print('theModularity');
//     // print(theModularity);

//     return Tuple2(communities, theModularity);
//   }

//   Tuple2<List<Set<int>>, double> louvainMethodPhase2(List<Set<int>> communitiesPh1,
//       Map<String, Map<String, double>> aPos, Map<String, Map<String, double>> aNeg) {
//     final numCommunities = communitiesPh1.length;

//     // Lump individuals into communities: compute B_pos and B_neg

//     final bPos = {
//       for (int i = 0; i < numCommunities; i++)
//         i.toString(): {for (int j = 0; j < numCommunities; j++) j.toString(): 0.0}
//     };
//     final bNeg = {
//       for (int i = 0; i < numCommunities; i++)
//         i.toString(): {for (int j = 0; j < numCommunities; j++) j.toString(): 0.0}
//     };

//     final communities = convertComFromIdx(communitiesPh1, aPos.keys.toList());

//     for (var i = 0; i < numCommunities; i++) {
//       for (var j = 0; j < numCommunities; j++) {
//         for (final k in communities[i]) {
//           for (final m in communities[j]) {
//             bPos[i.toString()]![j.toString()] = bPos[i.toString()]![j.toString()]! + aPos[k]![m]!;
//             bNeg[i.toString()]![j.toString()] = bNeg[i.toString()]![j.toString()]! + aNeg[k]![m]!;
//           }
//         }
//       }
//     }
//     // print('BValues');
//     // print(bPos);
//     // print(bNeg);

//     return louvainCMethodPhase1(numCommunities, bPos, bNeg);
//   }

//   double moveItoJ(
//       int numPlayers, Matrix comMatrix, double m, Vector K, Matrix A, int i, int comJ, int comI) {
//     // first, what is the change in modularity from putting i into j's community
//     var sigmaIn = 0.0;
//     for (var k = 0; k < numPlayers; k++) {
//       if (comMatrix[comJ][k] == 1) {
//         sigmaIn += comMatrix[comJ].dot(A[k]);
//       }
//     }
//     // print('sigmaIn');
//     // print(sigmaIn);

//     var sigmaTot = comMatrix[comJ].dot(K);
//     var kIin = comMatrix[comJ].dot(A[i]);

//     final twoM = 2 * m;
//     if (twoM == 0) {
//       return 0;
//     }

//     var a = (sigmaIn + 2 * kIin) / twoM;
//     var b = (sigmaTot + K[i]) / twoM;
//     var c = sigmaIn / twoM;
//     var d = sigmaTot / twoM;
//     var e = K[i] / twoM;
//     final dqIn = (a - (b * b)) - (c - d * d - e * e);

//     // second, what is the change in modularity from removing i from its community

//     final com = comMatrix[comI].toList();
//     com[i] = 0;
//     sigmaIn = 0;
//     for (var k = 0; k < numPlayers; k++) {
//       if (com[k] == 1) {
//         sigmaIn += Vector.fromList(com).dot(A[k]);
//       }
//     }

//     sigmaTot = Vector.fromList(com).dot(K);

//     kIin = Vector.fromList(com).dot(A[i]);

//     a = (sigmaIn + 2 * kIin) / twoM;
//     b = (sigmaTot + K[i]) / twoM;
//     c = sigmaIn / twoM;
//     d = sigmaTot / twoM;
//     e = K[i] / twoM;
//     final dQOut = (a - (b * b)) - (c - d * d - e * e);

//     return dqIn - dQOut;
//   }

//   double computeModularity(int numPlayers, List currentCommunities, Matrix A) {
//     final k = A.reduceRows((combine, vector) => combine + vector);
//     final m = A.sum();

//     if (m == 0) {
//       return 0;
//     }

//     var Q = 0.0;

//     for (var i = 0; i < numPlayers; i++) {
//       for (var j = 0; j < numPlayers; j++) {
//         Q += deltar(currentCommunities, i, j) * (A[i][j] - ((k[i] * k[j]) / (2 * m)));
//       }
//     }

//     Q /= 2 * m;

//     return Q;
//   }

//   int deltar(List currentCommunities, int i, int j) {
//     if (currentCommunities[i] == currentCommunities[j]) {
//       return 1;
//     } else {
//       return 0;
//     }
//   }

//   double computeCoalitionTarget(List<Set<String>> communities) {
//     // compute coalition_target
//     if (activeGenes!.coalitionTarget < 80) {
//       if (activeGenes!.coalitionTarget < 5) {
//         return .05;
//       } else {
//         return activeGenes!.coalitionTarget / 100;
//       }
//     } else if (currentRound.info.round < 3) {
//       return .51;
//     } else {
//       var inMx = false;
//       var mxIdx = -1;

//       final fuerza = <double>[];
//       final popularities = currentRound.info.playerPopularities;
//       final totPop = popularities.values.sum;
//       for (final s in communities) {
//         var tot = 0.0;
//         for (final i in s) {
//           tot += popularities[i]!;
//         }

//         fuerza.add(tot / totPop);
//         if (mxIdx == -1) {
//           mxIdx = 0;
//         } else if (tot > fuerza[mxIdx]) {
//           mxIdx = fuerza.length - 1;

//           inMx = s.contains(myPlayerName);
//         }
//       }
//       fuerza.sortReversed();

//       if (inMx) {
//         return min(fuerza[1] + .05, 55);
//       } else {
//         return min(fuerza[0] + .05, 55);
//       }
//     }
//   }

//   void updateIndebtedness(Map<String, int> transactionVec) {
//     final popularities = currentRound.info.playerPopularities;
//     final roundNum = currentRound.info.round;

//     //       # update the tally of indebtedness
//     final clippedTrans =
//         clipVector(transactionVec.map((key, value) => MapEntry(key, value.toDouble())));
//     tally.updateAll((key, value) => value - (clippedTrans[key]! * popularities[myPlayerName]!));

//     tally[myPlayerName] = 0;

//     var lmbda = 1 / roundNum; //+1;
//     if (lmbda < gameParams.popularityFunctionParams.alpha) {
//       lmbda = gameParams.popularityFunctionParams.alpha;
//     }
//     expectedReturn.updateAll((key, value) =>
//         ((1 - lmbda) * expectedReturn[key]!) +
//         (lmbda * (transactionVec[key]! * popularities[myPlayerName]!)));
//     aveReturn = expectedReturn.values.sum / expectedReturn.length;
//   }

//   List<Set<String>> convertComFromIdx(List<Set<int>> communitiesByIndex, List<String> players) {
//     final list = <Set<String>>[];

//     for (final community in communitiesByIndex) {
//       final members = <String>{};
//       for (final memberIdx in community) {
//         final memberName = players[memberIdx];
//         members.add(memberName);
//       }
//       list.add(members);
//     }

//     return list;
//   }

//   List<Set<int>> convertComToIdx(List<Set<String>> communitiesByString, List<String> players) {
//     final list = <Set<int>>[];

//     for (final community in communitiesByString) {
//       final members = <int>{};
//       for (final memberName in community) {
//         final memberIdx = players.indexOf(memberName);
//         members.add(memberIdx);
//       }
//       list.add(members);
//     }

//     return list;
//   }

//   CommunityEvaluation randomSelections(Set<String> playerSet, Map<String, double> popularities) {
//     final players = Set<String>.from(playerSet);
//     players.remove(myPlayerName);

//     final s = {myPlayerName};

//     var pop = popularities[myPlayerName]!;
//     final totalPop = popularities.values.sum;

//     // coalitionTarget = self.genes["coalitionTarget"] / 100.0

//     while ((pop / totalPop) < coalitionTarget) {
//       final String sel;
//       if (USE_RANDOM) {
//         sel = randomChoice(players);
//       } else {
//         sel = players.first;
//       }

//       s.add(sel);

//       players.remove(sel);
//       pop += popularities[sel]!;
//     }

//     return CommunityEvaluation(
//         s: s, centrality: 0, collectiveStrength: 0, familiarity: 0, modularity: 0, prosocial: 0);
//   }

//   List<Set<int>> enumerateCommunity(double modularityPh1, List<Set<int>> communitiesPh1,
//       double modularity, List<Set<int>> communitiesMegaByIndex) {
//     if (modularity > modularityPh1) {
//       final communities = <Set<int>>[];
//       for (final m in communitiesMegaByIndex) {
//         communities.add(<int>{});
//         for (final i in m) {
//           // ignore: prefer_foreach
//           for (final j in communitiesPh1[i]) {
//             communities[communities.length - 1].add(j);
//           }
//         }
//       }
//       return communities;
//     } else {
//       return communitiesPh1;
//     }
//   }

//   CommunityEvaluation envisionCommunities(
//       Map<String, Map<String, double>> aPos,
//       Map<String, Map<String, double>> aNeg,
//       List<Set<int>> communitiesPh1,
//       List<Set<int>> communitiesByIndex,
//       List<Set<String>> communities,
//       double modularity) {
//     observedCommunities = communities;
//     final potentialCommunities = <CommunityEvaluation>[];

//     var sIdx = findCommunity(communities);

//     final popularities = currentRound.info.playerPopularities;
//     final players = popularities.keys.toSet();

//     var curCommSize = 0.0;
//     for (final i in communities[sIdx]) {
//       curCommSize += popularities[i]!;
//     }
//     curCommSize /= popularities.values.sum;

//     var c = List<Set<String>>.from(communities).map(Set.from).toList();
//     final determineCommunitiesResult =
//         determineCommunities(communitiesByIndex, communities, sIdx, aPos, aNeg);
//     var s = determineCommunitiesResult[0] as Set<String>;
//     final m = determineCommunitiesResult[2] as double;

//     final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
//     s = removeMostlyDeadResult.first;
//     potentialCommunities.add(CommunityEvaluation(
//         s: s,
//         modularity: m,
//         centrality: getCentrality(s, currentRound.info.playerPopularities),
//         collectiveStrength:
//             getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
//         familiarity: getFamiliarity(
//             s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
//         prosocial: getIngroupAntisocial(s)));

//     // combine with any other group
//     for (final i in communities) {
//       if (i != s) {
//         c = List<Set<String>>.from(communities).map(Set<String>.from).toList();
//         c[sIdx] = c[sIdx].union(i);
//         if (!alreadyIn(c[sIdx], potentialCommunities)) {
//           c.remove(i);
//           final determineCommunitiesResult = determineCommunities(
//               convertComToIdx(c.cast(), currentRound.info.playerPopularities.keys.toList()),
//               c.cast(),
//               findCommunity(c.cast()),
//               aPos,
//               aNeg);
//           var s = determineCommunitiesResult[0] as Set<String>;
//           final m = determineCommunitiesResult[2] as double;
//           final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
//           s = removeMostlyDeadResult.first;

//           potentialCommunities.add(CommunityEvaluation(
//               s: s,
//               modularity: m,
//               centrality: getCentrality(s, currentRound.info.playerPopularities),
//               collectiveStrength:
//                   getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
//               familiarity: getFamiliarity(
//                   s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
//               prosocial: getIngroupAntisocial(s)));
//         }
//       }
//     }

//     // move to a different group
//     for (final i in communities) {
//       if (i != s) {
//         c = List<Set<String>>.from(communities).map(Set<String>.from).toList();
//         c[communities.indexOf(i)].add(myPlayerName);
//         if (!alreadyIn(c[communities.indexOf(i)], potentialCommunities)) {
//           c[sIdx].remove(myPlayerName);
//           final determineCommunitiesResult = determineCommunities(
//               convertComToIdx(c.cast(), players.toList()),
//               c.cast(),
//               communities.indexOf(i),
//               aPos,
//               aNeg);
//           var s = determineCommunitiesResult[0] as Set<String>;
//           final m = determineCommunitiesResult[2] as double;
//           final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
//           s = removeMostlyDeadResult.first;

//           potentialCommunities.add(CommunityEvaluation(
//               s: s,
//               modularity: m,
//               centrality: getCentrality(s, currentRound.info.playerPopularities),
//               collectiveStrength:
//                   getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
//               familiarity: getFamiliarity(
//                   s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
//               prosocial: getIngroupAntisocial(s)));
//         }
//       }
//     }

//     // add a member from another group
//     for (final i in players) {
//       if (!communities[sIdx].contains(i)) {
//         c = List<Set<String>>.from(communities).map(Set<String>.from).toList();
//         for (final s in c) {
//           if (s.contains(i)) {
//             s.remove(i);
//             break;
//           }
//         }
//         c[sIdx].add(i);
//         if (!alreadyIn(c[sIdx], potentialCommunities)) {
//           final determineCommunitiesResult = determineCommunities(
//               convertComToIdx(c.cast(), currentRound.info.playerPopularities.keys.toList()),
//               c.cast(),
//               findCommunity(c.cast()),
//               aPos,
//               aNeg);
//           var s = determineCommunitiesResult[0] as Set<String>;
//           final m = determineCommunitiesResult[2] as double;
//           final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
//           s = removeMostlyDeadResult.first;

//           potentialCommunities.add(CommunityEvaluation(
//               s: s,
//               modularity: m,
//               centrality: getCentrality(s, currentRound.info.playerPopularities),
//               collectiveStrength:
//                   getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
//               familiarity: getFamiliarity(
//                   s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
//               prosocial: getIngroupAntisocial(s)));
//         }
//       }
//     }

//     //subtract a member from the group (that isn't player_idx)
//     for (final i in communities[sIdx]) {
//       if (i != myPlayerName) {
//         c = List<Set<String>>.from(communities).map(Set<String>.from).toList();
//         c[sIdx].remove(i);
//         if (!alreadyIn(c[sIdx], potentialCommunities)) {
//           c.add(<String>{i});
//           final determineCommunitiesResult = determineCommunities(
//               convertComToIdx(c.cast(), players.toList()), c.cast(), sIdx, aPos, aNeg);
//           var s = determineCommunitiesResult[0] as Set<String>;
//           final m = determineCommunitiesResult[2] as double;
//           final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
//           s = removeMostlyDeadResult.first;

//           potentialCommunities.add(CommunityEvaluation(
//               s: s,
//               modularity: m,
//               centrality: getCentrality(s, currentRound.info.playerPopularities),
//               collectiveStrength:
//                   getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
//               familiarity: getFamiliarity(
//                   s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
//               prosocial: getIngroupAntisocial(s)));
//         }
//       }
//     }

//     final s2Idx = findCommunity(convertComFromIdx(communitiesPh1, players.toList()));
//     final communitiesPh1ByPlayer = convertComFromIdx(communitiesPh1, players.toList());
//     // if (sIdx != s2Idx) {
//     if (!communities[sIdx].deepEquals(communitiesPh1ByPlayer[s2Idx], ignoreOrder: true)) {
//       //TODO: double check this
//       sIdx = s2Idx;
//       // put in the original with combined other groups
//       c = List<Set<String>>.from(communitiesPh1ByPlayer).map(Set<String>.from).toList();
//       final determineCommunitiesResult = determineCommunities(
//           convertComToIdx(c.cast(), currentRound.info.playerPopularities.keys.toList()),
//           c.cast(),
//           sIdx,
//           aPos,
//           aNeg);
//       var s = determineCommunitiesResult[0] as Set<String>;
//       final m = determineCommunitiesResult[2] as double;
//       final removeMostlyDeadResult = removeMostlyDead(s, currentRound.info.playerPopularities);
//       s = removeMostlyDeadResult.first;
//       potentialCommunities.add(CommunityEvaluation(
//           s: s,
//           modularity: m,
//           centrality: getCentrality(s, currentRound.info.playerPopularities),
//           collectiveStrength:
//               getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
//           familiarity: getFamiliarity(
//               s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
//           prosocial: getIngroupAntisocial(s)));

//       // print('potential communities');
//       // for (final com in potentialCommunities) {
//       //   com.printCom();
//       // }

//       // combine with any other group
//       for (final i in communitiesPh1ByPlayer) {
//         if (i != s) {
//           c = List<Set<String>>.from(communitiesPh1ByPlayer).map(Set<String>.from).toList();
//           c[sIdx] = c[sIdx].union(i);
//           if (!alreadyIn(c[sIdx], potentialCommunities)) {
//             c.remove(i);
//             final determineCommunitiesResult = determineCommunities(
//                 convertComToIdx(c.cast(), currentRound.info.playerPopularities.keys.toList()),
//                 c.cast(),
//                 findCommunity(c.cast()),
//                 aPos,
//                 aNeg);
//             var s = determineCommunitiesResult[0] as Set<String>;
//             final m = determineCommunitiesResult[2] as double;
//             final removeMostlyDeadResult =
//                 removeMostlyDead(s, currentRound.info.playerPopularities);
//             s = removeMostlyDeadResult.first;

//             potentialCommunities.add(CommunityEvaluation(
//                 s: s,
//                 modularity: m,
//                 centrality: getCentrality(s, currentRound.info.playerPopularities),
//                 collectiveStrength:
//                     getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
//                 familiarity: getFamiliarity(
//                     s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
//                 prosocial: getIngroupAntisocial(s)));
//           }
//         }
//       }

//       // move to a different group
//       for (final i in communitiesPh1ByPlayer) {
//         if (i != s) {
//           c = List<Set<String>>.from(communitiesPh1ByPlayer).map(Set<String>.from).toList();
//           c[communitiesPh1ByPlayer.indexOf(i)].add(myPlayerName);
//           if (!alreadyIn(c[communitiesPh1ByPlayer.indexOf(i)], potentialCommunities)) {
//             c[sIdx].remove(myPlayerName);
//             final determineCommunitiesResult = determineCommunities(
//                 convertComToIdx(c.cast(), players.toList()),
//                 c.cast(),
//                 communitiesPh1ByPlayer.indexOf(i),
//                 aPos,
//                 aNeg);
//             var s = determineCommunitiesResult[0] as Set<String>;
//             final m = determineCommunitiesResult[2] as double;
//             final removeMostlyDeadResult =
//                 removeMostlyDead(s, currentRound.info.playerPopularities);
//             s = removeMostlyDeadResult.first;

//             potentialCommunities.add(CommunityEvaluation(
//                 s: s,
//                 modularity: m,
//                 centrality: getCentrality(s, currentRound.info.playerPopularities),
//                 collectiveStrength:
//                     getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
//                 familiarity: getFamiliarity(
//                     s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
//                 prosocial: getIngroupAntisocial(s)));
//           }
//         }
//       }

//       // # add a member from another group
//       for (final i in players) {
//         if (!communitiesPh1ByPlayer[sIdx].contains(i)) {
//           c = List<Set<String>>.from(communitiesPh1ByPlayer).map(Set<String>.from).toList();
//           for (final s in c) {
//             if (s.contains(i)) {
//               s.remove(i);
//               break;
//             }
//           }
//           c[sIdx].add(i);
//           if (!alreadyIn(c[sIdx], potentialCommunities)) {
//             final determineCommunitiesResult = determineCommunities(
//                 convertComToIdx(c.cast(), currentRound.info.playerPopularities.keys.toList()),
//                 c.cast(),
//                 findCommunity(c.cast()),
//                 aPos,
//                 aNeg);
//             var s = determineCommunitiesResult[0] as Set<String>;
//             final m = determineCommunitiesResult[2] as double;
//             final removeMostlyDeadResult =
//                 removeMostlyDead(s, currentRound.info.playerPopularities);
//             s = removeMostlyDeadResult.first;

//             potentialCommunities.add(CommunityEvaluation(
//                 s: s,
//                 modularity: m,
//                 centrality: getCentrality(s, currentRound.info.playerPopularities),
//                 collectiveStrength:
//                     getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
//                 familiarity: getFamiliarity(
//                     s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
//                 prosocial: getIngroupAntisocial(s)));
//           }
//         }
//       }

//       //subtract a member from the group (that isn't player_idx)
//       for (final i in communitiesPh1ByPlayer[sIdx]) {
//         if (i != myPlayerName) {
//           c = List<Set<String>>.from(communitiesPh1ByPlayer).map(Set<String>.from).toList();
//           c[sIdx].remove(i);
//           if (!alreadyIn(c[sIdx], potentialCommunities)) {
//             c.add(<String>{i});
//             final determineCommunitiesResult = determineCommunities(
//                 convertComToIdx(c.cast(), players.toList()), c.cast(), sIdx, aPos, aNeg);
//             var s = determineCommunitiesResult[0] as Set<String>;
//             final m = determineCommunitiesResult[2] as double;
//             final removeMostlyDeadResult =
//                 removeMostlyDead(s, currentRound.info.playerPopularities);
//             s = removeMostlyDeadResult.first;

//             potentialCommunities.add(CommunityEvaluation(
//                 s: s,
//                 modularity: m,
//                 centrality: getCentrality(s, currentRound.info.playerPopularities),
//                 collectiveStrength:
//                     getCollectiveStrength(currentRound.info.playerPopularities, s, curCommSize),
//                 familiarity: getFamiliarity(
//                     s, players, transposeMap(removeIntrinsic(currentRound.info.playerInfluences))),
//                 prosocial: getIngroupAntisocial(
//                   s,
//                 )));
//           }
//         }
//       }
//     }
//     var minMod = modularity;
//     for (final c in potentialCommunities) {
//       if (c.modularity < minMod) {
//         minMod = c.modularity;
//       }
//     }

//     var elegir = potentialCommunities[0];

//     var mx = -99999.0;
//     for (final c in potentialCommunities) {
//       if (modularity == minMod) {
//         c.modularity = 1.0;
//       } else {
//         c.modularity = (c.modularity - minMod) / (modularity - minMod);
//       }
//       c.computeScore(activeGenes!); //, coalitionTarget);
//       // print('SCORE');
//       // c.printCom();
//       if (c.score > mx) {
//         elegir = c;
//         mx = c.score;
//       }
//     }

//     meImporta = {for (final player in players) player: 0};
//     for (final i in elegir.s) {
//       var mejor = 1.0;
//       if (i != myPlayerName) {
//         for (final comm in potentialCommunities) {
//           if (!comm.s.contains(i)) {
//             mejor = min(mejor, (elegir.score - comm.score) / elegir.score);
//           }
//         }
//       }

//       meImporta[i] = mejor;
//     }
//     // print('elegir');
//     // elegir.printCom();

//     return elegir;
//   }

//   int findCommunity(List<Set<String>> communities) {
//     for (var i = 0; i < communities.length; i++) {
//       if (communities[i].contains(myPlayerName)) {
//         return i;
//       }
//     }
//     // ignore: avoid_print
//     print("Problem: Didn't find a community");

//     return -1;
//   }

//   List determineCommunities(List<Set<int>> c, List<Set<String>> cString, int sIdx,
//       Map<String, Map<String, double>> aPos, Map<String, Map<String, double>> aNeg) {
//     final players = currentRound.info.playerPopularities.keys.toSet();

//     final s = c[sIdx];
//     final sString = cString[sIdx];
//     c.removeAt(sIdx);

//     final cMega = louvainMethodPhase2(c, aPos, aNeg).first;
//     final cPrime = enumerateCommunity(0, c, 1, cMega); //Changed

//     cPrime.add(s);

//     final curComms = [for (int player = 0; player < players.length; player++) 0];
//     for (var j = 0; j < cPrime.length; j++) {
//       for (final i in cPrime[j]) {
//         curComms[i] = j;
//       }
//     }

//     final m = computeSignedModularity(currentRound.info.groupMembers.length, curComms, aPos, aNeg);

//     return [sString, cPrime, m];
//   }

//   double computeSignedModularity(int numPlayers, List<int> curComms,
//       Map<String, Map<String, double>> aPos, Map<String, Map<String, double>> aNeg) {
//     var modu = alpha * computeModularity(numPlayers, curComms, mapToMatrix(aPos));
//     modu -= (1 - alpha) * computeModularity(numPlayers, curComms, mapToMatrix(aNeg));

//     return modu;
//   }

//   double computeModularity2(int numPlayers, List<Set<int>> communities, Matrix A) {
//     final k = A.reduceRows((combine, vector) => combine + vector);
//     final m = A.sum();

//     if (m == 0) {
//       return 0;
//     }

//     var Q = 0.0;

//     for (var i = 0; i < numPlayers; i++) {
//       for (var j = 0; j < numPlayers; j++) {
//         Q += deltar2(communities, i, j) * (A[i][j] - ((k[i] * k[j]) / (2 * m)));
//       }
//     }

//     Q /= 2 * m;

//     return Q;
//   }

//   int deltar2(List<Set<int>> communities, int i, int j) {
//     for (final s in communities) {
//       if (s.contains(i) && s.contains(j)) {
//         return 1;
//       }
//     }
//     return 0;
//   }

//   Tuple2<Set<String>, Set<String>> removeMostlyDead(
//       Set<String> s, Map<String, double> popularities) {
//     final d = <String>{};
//     final sN = <String>{};
//     if (popularities[myPlayerName]! < 10) {
//       return Tuple2(d, sN);
//     }

//     for (final i in s) {
//       if (popularities[i]! < .1 * popularities[myPlayerName]!) {
//         d.add(i);
//       } else {
//         sN.add(i);
//       }
//     }
//     return Tuple2(sN, d);
//   }

//   double getCentrality(Set<String> s, Map<String, double> popularities) {
//     var groupSum = 0.0;
//     var mx = 0.0;
//     var numGreater = 0;

//     for (final i in s) {
//       groupSum += popularities[i]!;
//       if (popularities[i]! > mx) {
//         mx = popularities[i]!;
//       }
//       if (popularities[i]! > popularities[myPlayerName]!) {
//         numGreater += 1;
//       }
//     }

//     if (groupSum > 0.0 && s.length > 1) {
//       final aveSum = groupSum / s.length;
//       final aveVal = popularities[myPlayerName]! / aveSum;
//       final mxVal = popularities[myPlayerName]! / mx;
//       final rankVal = 1 - (numGreater / (s.length - 1.0));

//       return (aveVal + mxVal + rankVal) / 3.0;
//     } else {
//       return 1;
//     }
//   }

//   double getCollectiveStrength(
//       Map<String, double> popularities, Set<String> s, double curCommSize) {
//     var proposed = 0.0;
//     for (final i in s) {
//       proposed += popularities[i]!;
//     }

//     proposed /= popularities.values.sum;

//     double target;
//     if (activeGenes!.coalitionTarget == 0) {
//       target = .01;
//     } else {
//       target = activeGenes!.coalitionTarget / 100.0;
//     }

//     var base = 1.0 - ((target - curCommSize).abs() / target);
//     if (base < .01) {
//       base = .01;
//     }
//     base *= base;

//     if ((proposed - curCommSize).abs() <= 0.03) {
//       return base;
//     } else if ((curCommSize - target).abs() < (proposed - target).abs()) {
//       var nbase = 1.0 - ((target - proposed).abs() / target);
//       if (nbase < .01) {
//         nbase = .01;
//       }
//       return nbase * nbase;
//     } else {
//       final baseline = (1.0 + base) / 2.0;
//       final w = (proposed - target).abs() / (curCommSize - target).abs();
//       return ((1.0 - w) * 1.0) + (baseline * w);
//     }
//   }

//   double getFamiliarity(
//       Set<String> s, Set<String> players, Map<String, Map<String, double>> influences) {
//     // print(inflPos);
//     // print(influences);
//     var mag = 0.0;
//     for (final i in inflPos.keys) {
//       // print('i $i playerName: $playerName adding ${inflPos[i]![playerName]!}');
//       mag += inflPos[i]![myPlayerName]!;
//     }
//     if (mag > 0.0) {
//       final randval = mag / players.length;
//       var indLoyalty = 0.0;
//       var scaler = 1.0;

//       for (final i in s) {
//         if (scaledBackNums[i]! < 0.05 && i != myPlayerName) {
//           scaler *= (s.length - 1) / s.length;
//         }
//         if (influences[i]![myPlayerName]! * scaledBackNums[i]! > randval) {
//           indLoyalty += influences[i]![myPlayerName]! * scaledBackNums[i]!;
//         } else {
//           indLoyalty += (influences[i]![myPlayerName]! * scaledBackNums[i]!) - randval;
//         }
//       }
//       // print(scaler);
//       // print(indLoyalty);
//       // print(mag);
//       final double familiarity = max(.01, scaler * (indLoyalty / mag));

//       return familiarity;
//     } else {
//       return 1;
//     }
//   }

//   double getIngroupAntisocial(Set<String> s) {
//     var scl = 1.0;
//     final piece = 1.0 / s.length;
//     final remain = 1.0 - piece;
//     for (final i in s) {
//       if (i != myPlayerName) {
//         var theInvestment = 0.0;
//         var theReturn = 0.0;
//         for (final j in s) {
//           if (i != j) {
//             theInvestment += sumInflPos[j]![i]!;
//             theReturn += sumInflPos[i]![j]!;
//           }
//         }
//         if (theInvestment > 0.0) {
//           var val = theReturn / theInvestment;
//           if (val > 1.0) {
//             val = 1.0;
//           }
//           scl *= piece * val + remain;
//         }
//       }
//     }
//     return scl;
//   }

//   bool alreadyIn(Set s, List<CommunityEvaluation> potentialCommunities) {
//     for (final c in potentialCommunities) {
//       if (s.deepEquals(c.s, ignoreOrder: true)) {
//         return true;
//       }
//     }
//     return false;
//   }

//   double isKeeping(String otherPlayer, Iterable<String> players) {
//     var meAmount = 0.0;
//     var totalAmount = 0.0;
//     for (final i in players) {
//       if (currentRound.info.governmentRoundInfo.governmentPlayerNames?.contains(i) ?? false) {
//         continue;
//       }
//       if (i != otherPlayer) {
//         if (inflNeg[otherPlayer]![i]! > 0) {
//           totalAmount += inflNeg[otherPlayer]![i]! / gameParams.popularityFunctionParams.cSteal;
//           meAmount -= inflNeg[otherPlayer]![i]!;
//         } else {
//           totalAmount += inflPos[otherPlayer]![i]! / gameParams.popularityFunctionParams.cGive;
//         }
//       }
//     }

//     meAmount =
//         (meAmount + inflPos[otherPlayer]![otherPlayer]! - inflNeg[otherPlayer]![otherPlayer]!) /
//             gameParams.popularityFunctionParams.cKeep;

//     totalAmount += meAmount;

//     if (totalAmount > 0) {
//       return meAmount / totalAmount;
//     } else {
//       return 1;
//     }
//   }

//   double fearKeeping(Iterable<String> players, List<Set<String>> communities, String player) {
//     final amigos = findCommunityVec(players, communities, player);
//     final enemigos = (amigos - 1) * -1;

//     var sm = 0.0;

//     for (var i = 0; i < players.length; i++) {
//       if (amigos[i] == 1) {
//         sm = max(enemigos.dot(mapToMatrix(inflNeg).columns.toList()[i]), sm);
//       }
//     }

//     var denom = 0.0;
//     for (final i in inflPos.keys) {
//       denom += inflPos[i]![player]!;
//     }

//     var fearTokens = 0.0;
//     if (denom > 0) {
//       fearTokens = sm / denom;
//     }

//     // assume everyone else has the same fear I do
//     return min(1, fearTokens * (activeGenes!.fearDefense / 50));
//   }

//   Vector findCommunityVec(Iterable<String> players, List<Set<String>> communities, String player) {
//     final myCommVec = List.generate(players.length, (index) => 0);
//     for (final s in communities) {
//       if (s.contains(player)) {
//         for (final i in s) {
//           myCommVec[players.toList().indexOf(i)] = 1;
//         }
//       }
//     }
//     return Vector.fromList(myCommVec);
//   }

//   int cuantoGuardo(Set<String> selectedCommunity) {
//     final popularities = currentRound.info.playerPopularities;
//     final players = popularities.keys.toList();

//     if (popularities[myPlayerName]! <= gameParams.popularityFunctionParams.povertyLine) {
//       return 0;
//     }

//     if (currentRound.info.round == initialRound) {
//       underAttack = (activeGenes!.initialDefense / 100) * popularities[myPlayerName]!;
//     } else {
//       final totalAttack =
//           dotVectors(clipNegVector(currentRound.info.tokensReceived!), popularities);

//       final dUpdate = activeGenes!.defenseUpdate / 100;

//       underAttack = (underAttack * (1 - dUpdate)) + (totalAttack * dUpdate);
//     }

//     final numTokens = currentRound.info.playerTokens;
//     final caution = activeGenes!.defensePropensity / 50;
//     final selfDefenseTokens = min(numTokens,
//         (((underAttack * caution) / popularities[myPlayerName]!) * numTokens + .5).toInt());

//     // are there attacks on my friends by outsiders?  if so, consider keeping more tokens
//     // this can be compared to the self.fear_keeping function
//     final amigos = List.generate(players.length, (index) => 0);
//     final enemigos = List.generate(players.length, (index) => 0);

//     for (final player in players) {
//       if (selectedCommunity.contains(player)) {
//         enemigos[players.indexOf(player)] = 0;
//       } else {
//         amigos[players.indexOf(player)] = 0;
//       }
//     }

//     var sm = 0.0;
//     for (var i = 0; i < players.length; i++) {
//       if (amigos[i] == 1) {
//         sm = max(Vector.fromList(enemigos).dot(mapToMatrix(inflNeg).columns.toList()[i]), sm);
//       }
//     }

//     var denom = 0.0;
//     for (final i in inflPos.keys) {
//       denom += inflPos[i]![myPlayerName]!;
//     }

//     var fearTokens = 0;
//     if (denom > 0) {
//       fearTokens = (sm / denom * numTokens + .5).toInt();
//     }

//     fearTokens = ((fearTokens * activeGenes!.fearDefense) / 50 + .5).toInt();

//     final tokensGuardado = min(max(selfDefenseTokens, fearTokens), numTokens);
//     final minGuardado = ((activeGenes!.minKeep / 100) * numTokens + .5).toInt();

//     return max(tokensGuardado, minGuardado);
//   }

//   Tuple2<Map<String, int>, int> quienAtaco(
//       int remainingToks, Set<String> selectedCommunity, List<Set<String>> communities) {
//     final players = currentRound.info.playerPopularities.keys;
//     final groupCat = groupCompare(communities);

//     // print('remaining tokens: $remainingToks');

//     final pillageChoice = pillageTheVillage(selectedCommunity, remainingToks, groupCat);
//     // print('PILLAGERS : ${activeGenes!.pillagePriority}');
//     // print(pillageChoice);

//     final vengeanceChoice = takeVengeance(remainingToks);
//     // print('VENGEANCE');
//     // print(vengeanceChoice);
//     final defendFriendChoice =
//         defendFriend(remainingToks, selectedCommunity, communities, groupCat);

//     final attackToks = {for (final player in players) player: 0};

//     final attackPossibilities = <Tuple2<int, Tuple2<String?, int>>>[];
//     if (pillageChoice.first != null) {
//       attackPossibilities.add(Tuple2(activeGenes!.pillagePriority, pillageChoice));
//     }
//     if (vengeanceChoice.first != null) {
//       attackPossibilities.add(Tuple2(activeGenes!.vengeancePriority, vengeanceChoice));
//     }
//     if (defendFriendChoice.first != null) {
//       attackPossibilities.add(Tuple2(activeGenes!.defendFriendPriority, defendFriendChoice));
//     }

//     // decide which attack to do
//     if (attackPossibilities.isNotEmpty) {
//       attackPossibilities.sortReversed((a, b) => a.first.compareTo(b.first));
//       if ((attackPossibilities[0].second.first != defendFriendChoice[0]) ||
//           (attackPossibilities[0].second.second != defendFriendChoice[1])) {
//         expectedDefendFriendDamage = -99999;
//       }
//       attackToks[attackPossibilities[0].second.first!] = attackPossibilities[0].second.second;
//     } else {
//       expectedDefendFriendDamage = -99999;
//     }

//     return Tuple2(attackToks, attackToks.values.sum);
//   }

//   Tuple2<String?, int> pillageTheVillage(
//       Set<String> selectedCommunity, int remainingToks, Map<String, double> groupCat) {
//     final popularities = currentRound.info.playerPopularities;
//     final roundNum = currentRound.info.round;
//     final numTokens = currentRound.info.playerTokens;
//     final players = popularities.keys;
//     final influences = transposeMap(removeIntrinsic(currentRound.info.playerInfluences));
//     // print(
//     //     '$playerName fury: ${activeGenes!.pillageFury}, priority: ${activeGenes!.pillagePriority},  delay: ${activeGenes!.pillageDelay / 10}');

//     if ((popularities[myPlayerName]! <= 0) ||
//         (roundNum < (activeGenes!.pillageDelay / 10)) ||
//         (activeGenes!.pillagePriority < 50)) {
//       return const Tuple2(null, 0);
//     }

//     final numAttackTokens =
//         min(remainingToks, (numTokens * (activeGenes!.pillageFury / 100) + .5).toInt());
//     // print('$playerName num attack tokens: $numAttackTokens, fury: ${activeGenes!.pillageFury}');
//     if (numAttackTokens <= 0) {
//       return const Tuple2(null, 0);
//     }

//     var ratioPredictedSteals = 1.0;
//     final predictedSteals = clipNegVector(attacksWithMe).values.sum;
//     if (attacksWithMe[myPlayerName]! < 0) {
//       ratioPredictedSteals = predictedSteals / (-attacksWithMe[myPlayerName]!);
//     }

//     if (roundNum < 5) {
//       ratioPredictedSteals *= (activeGenes!.pillageCompanionship + 100) / 100;
//     }

//     final pillagePossibilities = <List>[];
//     for (final player in players) {
//       if ((currentRound.info.governmentRoundInfo.governmentPlayerNames?.contains(player) ??
//               false) ||
//           player == myPlayerName) {
//         continue;
//       }

//       if (groupCat[player]! < 2 &&
//           ((!selectedCommunity.contains(player)) || activeGenes!.pillageFriends >= 50)) {
//         // playerName is not fearful of the group player is in and player_idx is willing to pillage friends (if i is a friend)
//         var cantidad = numAttackTokens;
//         var myWeight = popularities[myPlayerName]! * cantidad;
//         var ratio = ratioPredictedSteals;
//         var ratio2 = (myWeight +
//                 ((othersAttackOn[player]! / gameParams.popularityFunctionParams.alpha) *
//                     numTokens)) /
//             myWeight;
//         if (ratio2 > ratioPredictedSteals) {
//           ratio = ratio2;
//         }
//         var gain = myWeight - (popularities[player]! * keepingStrength[player]! / ratio);
//         print('keeping strength 2: $gain');

//         // print('myWeight: $myWeight');
//         // print('popularities[$player]: ${popularities[player]}');
//         // print('ratio: $ratio');
//         // print('keeping strength $player: ${keepingStrength[player]}');

//         while (((((gain * ratio) / numTokens) *
//                     gameParams.popularityFunctionParams.alpha *
//                     gameParams.popularityFunctionParams.cSteal) >
//                 popularities[player]! - gameParams.popularityFunctionParams.povertyLine) &&
//             (cantidad > 0)) {
//           cantidad -= 1;

//           if (cantidad == 0) break;

//           myWeight = popularities[player]! * cantidad;
//           ratio = ratioPredictedSteals;
//           ratio2 = (myWeight +
//                   ((othersAttackOn[player]! / gameParams.popularityFunctionParams.alpha) *
//                       numTokens)) /
//               myWeight;
//           if (ratio2 > ratioPredictedSteals) {
//             ratio = ratio2;
//           }
//           gain = myWeight - (popularities[player]! * keepingStrength[player]! / ratio);
//           print('keeping strength 3: $gain');
//         }

//         if (cantidad == 0) continue;
//         // if (keepingStrength[player]! < 30) print('gain: $gain');
//         final stealROI = (gain * gameParams.popularityFunctionParams.cSteal) /
//             (cantidad * popularities[myPlayerName]!);
//         final damage = (gain / numTokens) *
//             gameParams.popularityFunctionParams.cSteal *
//             gameParams.popularityFunctionParams.alpha;

//         // if (keepingStrength[player]! < 30) print('cantidad: $cantidad, stealROI: $stealROI');
//         var immGainPerToken = stealROI *
//             ((cantidad / numTokens) * popularities[myPlayerName]!) *
//             gameParams.popularityFunctionParams.alpha;
//         // if (keepingStrength[player]! < 30) print('immGainPerToken 1: $immGainPerToken');
//         final friendPenalty = (1.0 - gameParams.popularityFunctionParams.beta) *
//             (damage / popularities[player]!) *
//             influences[player]![myPlayerName]!;
//         immGainPerToken -= friendPenalty;
//         // if (keepingStrength[player]! < 30) print('immGainPerToken 2: $immGainPerToken');
//         // if (keepingStrength[player]! < 30) {
//         //   print(
//         //       'ROI: $ROI, numTokens: $numTokens, popularities[$playerName]: ${popularities[playerName]}');
//         // }
//         immGainPerToken -= ROI *
//             ((cantidad / numTokens) * popularities[myPlayerName]!) *
//             gameParams.popularityFunctionParams.alpha;
//         // if (keepingStrength[player]! < 30) print('immGainPerToken 3: $immGainPerToken');

//         immGainPerToken /= cantidad;
//         // if (keepingStrength[player]! < 30) print('immGainPerToken 4: $immGainPerToken');

//         //identify security threats
//         final securityThreatAdvantage = immGainPerToken + damage / cantidad;
//         final num myGrowth;
//         final num theirGrowth;
//         if (roundNum > initialRound + 3) {
//           myGrowth = (currentRound.popularities[roundNum]![myPlayerName]! -
//                   currentRound.popularities[roundNum - 4]![myPlayerName]!) /
//               4.0;

//           theirGrowth = (currentRound.popularities[roundNum]![player]! -
//                   currentRound.popularities[roundNum - 4]![player]!) /
//               4.0;
//         } else {
//           myGrowth = 0;
//           theirGrowth = 0;
//         }

//         if ((theirGrowth > (1.5 * myGrowth)) &&
//                 (popularities[player]! > popularities[myPlayerName]!) &&
//                 (!selectedCommunity.contains(player)) ||
//             groupCat[player] == 1) {
//           immGainPerToken += securityThreatAdvantage;
//         }

//         final margin = activeGenes!.pillageMargin / 100;
//         // print('immGainPerToken: $immGainPerToken');
//         if (immGainPerToken > margin) {
//           pillagePossibilities.add([player, immGainPerToken, cantidad]);
//         }
//       }
//     }

//     // print('PILLAGE POSSIBILITIES');
//     // print(pillagePossibilities);

//     // random selection
//     if (pillagePossibilities.isNotEmpty) {
//       var mag = 0.0;
//       for (final i in pillagePossibilities) {
//         mag += i[1]! as double;
//       }

//       double num;
//       if (USE_RANDOM) {
//         num = Random().nextDouble();
//       } else {
//         num = .5;
//       }

//       var sumR = 0.0;

//       for (final i in pillagePossibilities) {
//         sumR += (i[1]! as double) / mag;
//         if (num <= sumR) {
//           return Tuple2(i[0] as String, i[2] as int);
//         }
//       }
//     }

//     return const Tuple2(null, 0);
//   }

//   Tuple2<String?, int> takeVengeance(int tokensRemaining) {
//     final popularities = currentRound.info.playerPopularities;
//     final numTokens = currentRound.info.playerTokens;
//     final players = popularities.keys;
//     final influences = transposeMap(removeIntrinsic(currentRound.info.playerInfluences));
//     if (popularities[myPlayerName]! <= 0 || activeGenes!.vengeancePriority < 50) {
//       return const Tuple2(null, 0);
//     }
//     final multiplicador = activeGenes!.vengeanceMultiplier / 33.0;
//     final vengenceMax = min(numTokens * activeGenes!.vengeanceMax / 100.0, tokensRemaining);

//     var ratioPredictedSteals = 1.0;
//     final predictedSteals = clipNegVector(attacksWithMe).values.sum;
//     if (attacksWithMe[myPlayerName]! < 0) {
//       ratioPredictedSteals = predictedSteals / (-attacksWithMe[myPlayerName]!);
//     }

//     final vengencePossibilities = <List>[];
//     for (final player in players) {
//       if ((currentRound.info.governmentRoundInfo.governmentPlayerNames?.contains(player) ??
//               false) ||
//           player == myPlayerName) {
//         continue;
//       }

//       if (influences[player]![myPlayerName]! < 0 &&
//           -influences[player]![myPlayerName]! > (.5 * popularities[myPlayerName]!) &&
//           influences[player]![myPlayerName]! < influences[myPlayerName]![player]! &&
//           popularities[player]! > .01) {
//         final keepingStrengthW =
//             keepingStrength[player]! * (popularities[player]! / popularities[myPlayerName]!);
//         print('keeping strength 4: $keepingStrengthW');

//         final theScore = numTokens *
//             ((influences[player]![myPlayerName]! - influences[myPlayerName]![player]!) /
//                 (popularities[myPlayerName]! *
//                     gameParams.popularityFunctionParams.cSteal *
//                     gameParams.popularityFunctionParams.alpha));
//         var cantidad =
//             (min(-1.0 * (theScore - keepingStrengthW) * multiplicador, vengenceMax) + 0.5).toInt();

//         if (cantidad <= 0) {
//           continue;
//         }

//         var myWeight = popularities[myPlayerName]! * cantidad;
//         var ratio = ratioPredictedSteals;
//         var ratio2 = (myWeight +
//                 ((othersAttackOn[player]! / gameParams.popularityFunctionParams.alpha) *
//                     numTokens)) /
//             myWeight;
//         if (ratio2 > ratioPredictedSteals) {
//           ratio = ratio2;
//         }
//         var gain = myWeight - (popularities[player]! * keepingStrength[player]! / ratio);
//         print('keeping strength 5: $gain');

//         while (((((gain * ratio) / numTokens) *
//                     gameParams.popularityFunctionParams.alpha *
//                     gameParams.popularityFunctionParams.cSteal) >
//                 (popularities[player]! - gameParams.popularityFunctionParams.povertyLine)) &&
//             (cantidad > 0)) {
//           cantidad -= 1;
//           if (cantidad == 0) break;

//           myWeight = popularities[myPlayerName]! * cantidad;
//           ratio = ratioPredictedSteals;
//           ratio2 = (myWeight +
//                   ((othersAttackOn[player]! / gameParams.popularityFunctionParams.alpha) *
//                       numTokens)) /
//               myWeight;
//           if (ratio2 > ratioPredictedSteals) ratio = ratio2;
//           gain = myWeight - (popularities[player]! * keepingStrength[player]! / ratio);
//           print('keeping strength 6: $gain');
//         }

//         final stealROI = (gain * gameParams.popularityFunctionParams.cSteal) /
//             (cantidad * popularities[myPlayerName]!);
//         final damage = (gain / numTokens) *
//             gameParams.popularityFunctionParams.cSteal *
//             gameParams.popularityFunctionParams.alpha;

//         var immGainPerToken = (stealROI - ROI) *
//             ((cantidad / numTokens) * popularities[myPlayerName]!) *
//             gameParams.popularityFunctionParams.alpha;
//         immGainPerToken /= cantidad;

//         final vengenceAdvantage = immGainPerToken + damage / cantidad;

//         if (vengenceAdvantage > 0) {
//           vengencePossibilities.add([player, vengenceAdvantage, cantidad]);
//         }
//       }
//     }

//     // random selection
//     if (vengencePossibilities.isNotEmpty) {
//       var mag = 0.0;
//       for (final i in vengencePossibilities) {
//         mag += i[1]! as double;
//       }

//       double num;
//       if (USE_RANDOM) {
//         num = Random().nextDouble();
//       } else {
//         num = .5;
//       }

//       var sumr = 0.0;

//       for (final i in vengencePossibilities) {
//         sumr += (i[1]! as double) / mag;
//         if (num <= sumr) {
//           return Tuple2(i[0] as String, i[2] as int);
//         }
//       }
//     }
//     return const Tuple2(null, 0);
//   }

//   Tuple2<String?, int> defendFriend(int remainingToks, Set<String> selectedCommunity,
//       List<Set<String>> communities, Map<String, double> groupCat) {
//     final popularities = currentRound.info.playerPopularities;
//     final players = popularities.keys;
//     final numTokens = currentRound.info.playerTokens;
//     expectedDefendFriendDamage = -99999;
//     // print('DEFEND FRIEND ($myPlayerName)');
//     // print('defend friend priority: ${activeGenes!.defendFriendPriority}');
//     // print(inflPosSumCol[myPlayerName]! <= 0);

//     if ((popularities[myPlayerName]! <= 0) ||
//         (inflPosSumCol[myPlayerName]! <= 0) ||
//         (activeGenes!.defendFriendPriority < 50)) return const Tuple2(null, 0);

//     final myCommVec = {for (final player in players) player: 0.0};
//     for (final i in selectedCommunity) {
//       if ((i == myPlayerName) | (meImporta[i]! > 0.1)) myCommVec[i] = 1.0;
//     }

//     final badMarks = {for (final player in players) player: 0.0};
//     String? worstInd;
//     var worstVal = 0.0;

//     for (final player in players) {
//       if ((currentRound.info.governmentRoundInfo.governmentPlayerNames?.contains(player) ??
//               false) ||
//           (player == myPlayerName) ||
//           ((activeGenes!.attackGoodGuys < 50) && (badGuys[player]! < 0.2)) ||
//           (groupCat[player] == 2)) {
//         continue;
//       }

//       badMarks[player] = dotVectors(inflNeg[player]!, myCommVec);
//       if (badMarks[player]! > 0) {
//         final influenceOnPlayer = inflNeg.map((key, value) => MapEntry(key, value[player]!));
//         badMarks[player] = badMarks[player]! - dotVectors(influenceOnPlayer, myCommVec);
//       }

//       badMarks[player] = adjustBadMarks(badMarks[player]!, player);

//       if (popularities[player]! - gameParams.popularityFunctionParams.povertyLine <
//           badMarks[player]!) {
//         badMarks[player] = popularities[player]! - gameParams.popularityFunctionParams.povertyLine;
//       }

//       if (badMarks[player]! > worstVal && myCommVec[player] == 0) {
//         worstInd = player;
//         worstVal = badMarks[worstInd]!;
//       }

//       if (worstInd != null) {
//         // see how many tokens I should use on this attack
//         var tokensNeeded = numTokens *
//             badMarks[worstInd]! /
//             (popularities[myPlayerName]! *
//                 gameParams.popularityFunctionParams.cSteal *
//                 gameParams.popularityFunctionParams.alpha);
//         tokensNeeded +=
//             keepingStrength[worstInd]! * (popularities[worstInd]! / popularities[myPlayerName]!);
//         print('keeping strength 7: $tokensNeeded');

//         final multiplicador = activeGenes!.defendFriendMultiplier / 33.0;
//         tokensNeeded *= multiplicador;
//         final attackStrength = dotVectors(popularities, myCommVec) * inflictedDamageRatio;
//         final myPart = tokensNeeded * (popularities[myPlayerName]! / attackStrength);
//         final cantidad = min(
//             (myPart + 0.5).toInt(),
//             min((((activeGenes!.defendFriendMax / 100.0) * numTokens) + 0.5).toInt(),
//                 remainingToks));

//         if ((cantidad >= (myPart - 1)) && (tokensNeeded > 0)) {
//           // see if the attack is a good idea
//           final gain = (tokensNeeded * popularities[myPlayerName]!) -
//               (popularities[worstInd]! * keepingStrength[worstInd]!);
//           print('keeping strength 8: $gain');

//           final stealROI = (gain * gameParams.popularityFunctionParams.cSteal) /
//               (tokensNeeded * popularities[myPlayerName]!);
//           final immGainPerToken = (stealROI - ROI) *
//               popularities[myPlayerName]! *
//               gameParams.popularityFunctionParams.alpha;
//           double vengenceAdvantage;
//           if (groupCat[worstInd] == 0 && activeGenes!.groupAware >= 50) {
//             // defend more violently against weaker groups (if group aware)
//             vengenceAdvantage = immGainPerToken +
//                 2.0 * ((gain * gameParams.popularityFunctionParams.alpha) / tokensNeeded);
//           } else {
//             vengenceAdvantage =
//                 immGainPerToken + (gain * gameParams.popularityFunctionParams.alpha) / tokensNeeded;
//           }

//           if (vengenceAdvantage > 0.0) {
//             expectedDefendFriendDamage = gain *
//                 gameParams.popularityFunctionParams.alpha *
//                 gameParams.popularityFunctionParams.cSteal /
//                 numTokens;
//             return Tuple2(worstInd, cantidad);
//           }
//         }
//       }
//     }
//     return const Tuple2(null, 0);
//   }

//   Tuple2<Map<String, int>, int> groupGivings(
//       int numGivingTokens, CommunityEvaluation selectedCommunity, Map<String, int> attackAlloc) {
//     final players = currentRound.info.playerPopularities.keys;

//     if (numGivingTokens <= 0) {
//       final groupAlloc = {for (final player in players) player: 0};
//       return Tuple2(groupAlloc, 0);
//     }

//     // allocate tokens based on homophily

//     final homophilyVec = getHomophilyVec();
//     final homophilyAllocateResult =
//         homophilyAllocateTokens(numGivingTokens, homophilyVec, attackAlloc);
//     final homophilyAlloc = homophilyAllocateResult.first;
//     final numTokensH = homophilyAllocateResult.second;

//     // print(numTokensH);
//     // print(numGivingTokens);

//     final groupAllocateResult =
//         groupAllocateTokens(numGivingTokens - numTokensH, selectedCommunity, attackAlloc);
//     var groupAlloc = groupAllocateResult.first;
//     final numTokensG = groupAllocateResult.second;

//     // for now, just keep tokens that you don't know what to do with
//     groupAlloc[myPlayerName] =
//         groupAlloc[myPlayerName]! + (numGivingTokens - (numTokensH + numTokensG));

//     // print('groupAlloc');
//     // print(groupAlloc);
//     if (currentRound.info.playerPopularities[myPlayerName]! > 0.0001) {
//       groupAlloc =
//           dialBack(currentRound.info.playerTokens, addIntVectors(homophilyAlloc, groupAlloc)).first;
//     }

//     return Tuple2(groupAlloc, groupAlloc.values.sum);
//   }

//   Map<String, int> getHomophilyVec() {
//     final players = currentRound.info.playerPopularities.keys;
//     final homophilyVec = {for (final player in players) player: 0};
//     for (final player in players) {
//       if (player != myPlayerName) {
//         // print(genes!.homophily);
//         if (activeGenes!.homophily > 66 && getVisualHomophilySimilarity(player) > 0) {
//           homophilyVec[player] = 1;
//         } else if (activeGenes!.homophily < 34 && getVisualHomophilySimilarity(player) == 0) {
//           homophilyVec[player] = 1;
//         } else {
//           homophilyVec[player] = 0;
//         }
//       }
//     }

//     // print(homophilyVec);
//     return homophilyVec;
//   }

//   int getVisualHomophilySimilarity(String player) {
//     final diff = (visualTraits[myPlayerName]! - visualTraits[player]!).abs();
//     if (diff < 20) {
//       return 1;
//     } else {
//       return 0;
//     }
//   }

//   Tuple2<Map<String, int>, int> homophilyAllocateTokens(
//       int numGivingTokens, Map<String, int> homophilyVec, Map<String, int> attackAlloc) {
//     final toks = {for (final player in currentRound.info.playerPopularities.keys) player: 0};
//     return Tuple2(toks, 0);
//   }

//   Tuple2<Map<String, int>, int> groupAllocateTokens(
//       int numTokens, CommunityEvaluation theCommunity, Map<String, int> attackAlloc) {
//     final players = currentRound.info.playerPopularities.keys;
//     final roundNum = currentRound.info.round;
//     final sModified = Set<String>.from(theCommunity.s);

//     // print(numTokens);
//     // theCommunity.printCom();
//     // print(attackAlloc);
//     for (final player in players) {
//       if (attackAlloc[player]! != 0) {
//         if (sModified.contains(player)) {
//           sModified.remove(player);
//         }
//       }
//     }

//     final toks = {for (final player in players) player: 0};

//     var numAllocated = numTokens;
//     if (roundNum == initialRound) {
//       if (sModified.length == 1) {
//         toks[myPlayerName] = numTokens;
//       } else {
//         for (var i = 0; i < numTokens; i++) {
//           String sel;
//           if (USE_RANDOM) {
//             sel = randomChoice(sModified);
//           } else {
//             sel = sModified.toList().first;
//           }
//           while (sel == myPlayerName) {
//             if (USE_RANDOM) {
//               sel = randomChoice(sModified);
//             } else {
//               sel = sModified.toList()[1];
//             }
//           }
//           toks[sel] = toks[sel]! + 1;
//         }
//       }
//     } else {
//       var commSize = sModified.length;
//       if (commSize <= 1) {
//         toks[myPlayerName] = numTokens;
//       } else {
//         final profile = <Tuple2<String, double>>[];
//         var mag = 0.0;
//         for (final i in sModified) {
//           if (i != myPlayerName) {
//             final sb = scaledBackNums[i]!;
//             if (sb > 0) {
//               final val = (inflPos[i]![myPlayerName]! + 0.01) * sb;
//               profile.add(Tuple2(i, val));
//               mag += val;
//             }
//           }
//         }

//         if (mag > 0) {
//           profile.sortReversed((a, b) => a.second.compareTo(b.second));
//           var remainingToks = numTokens;
//           commSize = profile.length;
//           final fixedUsage = ((activeGenes!.fixedUsage / 100.0) * numTokens) / commSize;

//           final flexTokens = numTokens - (fixedUsage * commSize);
//           for (var i = 0; i < commSize; i++) {
//             // print(  'fixedUsage: $fixedUsage, flexTokens: $flexTokens, profile: ${profile[i].second} mag: $mag, remainingToks: $remainingToks');
//             final giveEm = (fixedUsage + flexTokens * (profile[i].second / mag) + 0.5).toInt();
//             if (remainingToks >= giveEm) {
//               toks[profile[i].first] = toks[profile[i].first]! + giveEm;
//               remainingToks -= giveEm;
//             } else {
//               toks[profile[i].first] = toks[profile[i].first]! + remainingToks;
//               remainingToks = 0;
//             }
//           }

//           while (remainingToks > 0) {
//             for (var i = 0; i < commSize; i++) {
//               toks[profile[i].first] = toks[profile[i].first]! + 1;
//               remainingToks -= 1;

//               if (remainingToks == 0) break;
//             }
//           }
//         } else {
//           numAllocated = 0;
//         }
//       }
//     }

//     return Tuple2(toks, numAllocated);
//   }

//   Tuple2<Map<String, int>, int> dialBack(int playerTokens, Map<String, int> giveAlloc) {
//     final popularities = currentRound.info.playerPopularities;
//     final players = currentRound.info.playerPopularities.keys;
//     final numTokens = currentRound.info.playerTokens;
//     final percLmt = (activeGenes!.limitingGive) / 100.0;
//     // print(giveAlloc);
//     var shave = 0;
//     for (final player in players) {
//       if (player == myPlayerName) {
//         continue;
//       }
//       if (giveAlloc[player]! > 0) {
//         final lmt =
//             (((popularities[player]! / popularities[myPlayerName]!) * numTokens * percLmt) + 0.5)
//                 .toInt();
//         if (lmt < giveAlloc[player]!) {
//           shave += giveAlloc[player]! - lmt;
//           giveAlloc[player] = lmt;
//         }
//       }
//     }
//     // print(shave);

//     giveAlloc[myPlayerName] = giveAlloc[myPlayerName]! + shave;

//     return Tuple2(giveAlloc, shave);
//   }

//   /// Determines relationship (in size) of player_idx's group with that of the other groups
//   /// -1: in same group
//   /// 0: (no competition) player_idx's group is much bigger
//   /// 1: (rivals) player_idx's group if somewhat the same size and one of us is in the most powerful group
//   /// 2: (fear) player_idx's group is much smaller

//   Map<String, double> groupCompare(List<Set<String>> communities) {
//     final popularities = currentRound.info.playerPopularities;
//     final players = popularities.keys;

//     final groupCat = {for (final player in players) player: 0.0};
//     if (activeGenes!.groupAware < 50) {
//       //     # don't do anything different -- player is not group aware
//       return groupCat;
//     }

//     final commIdx = {for (final player in players) player: 0};
//     final poders = {for (var c = 0; c < players.length; c++) c: 0.0};

//     for (var c = 0; c < communities.length; c++) {
//       for (final i in communities[c]) {
//         commIdx[i] = c;
//         poders[c] = poders[c]! + popularities[i]!;
//       }
//     }

//     final mxPoder = poders.values.max;

//     const scaler = 1.3; //this is arbitary for now
//     for (final player in players) {
//       if (commIdx[player] == commIdx[myPlayerName]) {
//         groupCat[player] = -1;
//       } else if (poders[commIdx[player]]! > (scaler * poders[commIdx[myPlayerName]]!)) {
//         groupCat[player] = 2;
//       } else if (((scaler * poders[commIdx[player]]!) > poders[commIdx[myPlayerName]]!) &&
//           ((poders[commIdx[player]] == mxPoder) || (poders[commIdx[myPlayerName]] == mxPoder))) {
//         groupCat[player] = 1;
//       } else if (popularities[player]! > popularities[myPlayerName]!) {
//         groupCat[player] = 1;
//       }
//     }

//     return groupCat;
//   }

//   double adjustBadMarks(double currentMarks, String player) {
//     return currentMarks;
//   }
// }

// Future<void> main() async {
//   print('testing...');

//   final agent = GeneAgentTest(
//       genes:
//           'genes_47_60_74_67_43_86_89_62_54_92_31_22_16_78_35_40_83_69_55_0_68_32_20_70_45_88_69_69_75_93_41_41_0_0_0_0_0_0_0_47_60_74_67_43_86_89_62_54_92_31_22_16_78_35_40_83_69_55_0_68_32_20_70_45_88_69_69_75_93_41_41_0_0_0_0_0_0_0_47_60_74_67_43_86_89_62_54_92_31_22_16_78_35_40_83_69_55_0_68_32_20_70_45_88_69_69_75_93_41_41_0_0_0_0_0_0_0');
//   const gameParams = GameParams();
//   const playerName = 'Alpha';
//   var currentRound = RoundState(
//       info: PlayerRoundInfo(
//           status: GameStatus.started,
//           round: 1,
//           endTime: DateTime.now(),
//           governmentRoundInfo: const GovernmentRoundInfo(round: 0),
//           playerName: 'Alpha',
//           playerLabels: {'Alpha': {}, 'November': {}, 'Zulu': {}},
//           playerPopularities: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0},
//           playerInfluences: {
//             'Alpha': {'Alpha': 0.0, 'November': 0.0, 'Zulu': 0.0, '__intrinsic__': 100.0},
//             'November': {'Alpha': 0.0, 'November': 0.0, 'Zulu': 0.0, '__intrinsic__': 100.0},
//             'Zulu': {'Alpha': 0.0, 'November': 0.0, 'Zulu': 0.0, '__intrinsic__': 100.0}
//           },
//           groupMembers: {'Alpha', 'November', 'Zulu'},
//           playerTokens: 6,
//           tokensGiven: {},
//           tokensReceived: {},
//           colorGroups: {'Alpha': null, 'November': null, 'Zulu': null}),
//       popularities: {
//         1: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0}
//       },
//       networkGraph: const NetworkGraph(nodes: [], edges: []),
//       networkGraph3d: const NetworkGraph3d(nodes: [], edges: []));

//   await agent.nextRound(currentRound, playerName, gameParams);
//   currentRound = RoundState(
//       info: PlayerRoundInfo(
//           status: GameStatus.started,
//           round: 2,
//           endTime: DateTime.now(),
//           governmentRoundInfo: const GovernmentRoundInfo(round: 0),
//           playerName: 'Alpha',
//           playerLabels: {'Alpha': {}, 'November': {}, 'Zulu': {}},
//           playerPopularities: {
//             'Alpha': 111.16666666666667,
//             'November': 109.16666666666667,
//             'Zulu': 93.0
//           },
//           playerInfluences: {
//             'Alpha': {
//               'Alpha': 9.5,
//               'November': 8.666666666666668,
//               'Zulu': 13.0,
//               '__intrinsic__': 80.0
//             },
//             'November': {
//               'Alpha': 13.0,
//               'November': 3.1666666666666665,
//               'Zulu': 13.0,
//               '__intrinsic__': 80.0
//             },
//             'Zulu': {'Alpha': 0.0, 'November': 13.0, 'Zulu': 0.0, '__intrinsic__': 80.0}
//           },
//           groupMembers: {'Alpha', 'November', 'Zulu'},
//           playerTokens: 6,
//           tokensGiven: {'Alpha': 3.0, 'November': 3.0, 'Zulu': 0.0},
//           tokensReceived: {'Alpha': 3.0, 'November': 2.0, 'Zulu': 3.0},
//           colorGroups: {'Alpha': null, 'November': null, 'Zulu': null}),
//       popularities: {
//         1: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0},
//         2: {'Alpha': 111.16666666666667, 'November': 109.16666666666667, 'Zulu': 93.0}
//       },
//       networkGraph: const NetworkGraph(edges: [], nodes: []),
//       networkGraph3d: const NetworkGraph3d(edges: [], nodes: []));

//   await agent.nextRound(currentRound, playerName, gameParams);

//   currentRound = RoundState(
//       info: PlayerRoundInfo(
//           status: GameStatus.started,
//           round: 3,
//           endTime: DateTime.now(),
//           governmentRoundInfo: const GovernmentRoundInfo(round: 0),
//           playerName: 'Alpha',
//           playerLabels: {'Alpha': {}, 'November': {}, 'Zulu': {}},
//           playerPopularities: {
//             'Alpha': 126.30791371158395,
//             'November': 108.09271867612296,
//             'Zulu': 93.7306619385343
//           },
//           playerInfluences: {
//             'Alpha': {
//               'Alpha': 18.40540780141844,
//               'November': 26.01229314420804,
//               'Zulu': 17.89021276595745,
//               '__intrinsic__': 64.00000000000001
//             },
//             'November': {
//               'Alpha': 15.551903073286052,
//               'November': 2.5906028368794325,
//               'Zulu': 25.95021276595745,
//               '__intrinsic__': 64.00000000000001
//             },
//             'Zulu': {
//               'Alpha': 9.634444444444446,
//               'November': 20.096217494089835,
//               'Zulu': 0.0,
//               '__intrinsic__': 64.00000000000001
//             }
//           },
//           groupMembers: {'Alpha', 'November', 'Zulu'},
//           playerTokens: 6,
//           tokensGiven: {'Alpha': 3.0, 'November': 1.0, 'Zulu': 2.0},
//           tokensReceived: {'Alpha': 3.0, 'November': 4.0, 'Zulu': 2.0},
//           colorGroups: {'Alpha': null, 'November': null, 'Zulu': null}),
//       popularities: {
//         1: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0},
//         2: {'Alpha': 111.16666666666667, 'November': 109.16666666666667, 'Zulu': 93.0},
//         3: {'Alpha': 126.30791371158395, 'November': 108.09271867612296, 'Zulu': 93.7306619385343}
//       },
//       networkGraph: const NetworkGraph(edges: [], nodes: []),
//       networkGraph3d: const NetworkGraph3d(edges: [], nodes: []));

//   await agent.nextRound(currentRound, playerName, gameParams);

//   currentRound = RoundState(
//       info: PlayerRoundInfo(
//           status: GameStatus.started,
//           round: 4,
//           endTime: DateTime.now(),
//           governmentRoundInfo: const GovernmentRoundInfo(round: 0),
//           playerName: 'Alpha',
//           playerLabels: {'Alpha': {}, 'November': {}, 'Zulu': {}},
//           playerPopularities: {
//             'Alpha': 139.08557997324937,
//             'November': 107.79018785456995,
//             'Zulu': 89.24655836088674
//           },
//           playerInfluences: {
//             'Alpha': {
//               'Alpha': 27.357401376255694,
//               'November': 34.29148977528135,
//               'Zulu': 26.2366888217123,
//               '__intrinsic__': 51.20000000000001
//             },
//             'November': {
//               'Alpha': 23.928117007367195,
//               'November': 12.283575699519393,
//               'Zulu': 20.378495147683363,
//               '__intrinsic__': 51.20000000000001
//             },
//             'Zulu': {
//               'Alpha': 13.508326981193235,
//               'November': 15.633818495532735,
//               'Zulu': 8.904412884160758,
//               '__intrinsic__': 51.20000000000001
//             }
//           },
//           groupMembers: {'Alpha', 'November', 'Zulu'},
//           playerTokens: 6,
//           tokensGiven: {'Alpha': 3.0, 'November': 2.0, 'Zulu': 1.0},
//           tokensReceived: {'Alpha': 3.0, 'November': 3.0, 'Zulu': 3.0},
//           colorGroups: {'Alpha': null, 'November': null, 'Zulu': null}),
//       popularities: {
//         1: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0},
//         2: {'Alpha': 111.16666666666667, 'November': 109.16666666666667, 'Zulu': 93.0},
//         3: {'Alpha': 126.30791371158395, 'November': 108.09271867612296, 'Zulu': 93.7306619385343},
//         4: {'Alpha': 139.08557997324937, 'November': 107.79018785456995, 'Zulu': 89.24655836088674}
//       },
//       networkGraph: const NetworkGraph(edges: [], nodes: []),
//       networkGraph3d: const NetworkGraph3d(edges: [], nodes: []));

//   await agent.nextRound(currentRound, playerName, gameParams);

//   currentRound = RoundState(
//       info: PlayerRoundInfo(
//           status: GameStatus.started,
//           round: 5,
//           endTime: DateTime.now(),
//           governmentRoundInfo: const GovernmentRoundInfo(round: 0),
//           playerName: 'Alpha',
//           playerLabels: {'Alpha': {}, 'November': {}, 'Zulu': {}},
//           playerPopularities: {
//             'Alpha': 127.28532453772095,
//             'November': 98.34715613895094,
//             'Zulu': 102.41403144619589
//           },
//           playerInfluences: {
//             'Alpha': {
//               'Alpha': 35.94447272367357,
//               'November': 36.416148115935876,
//               'Zulu': 13.964703698111485,
//               '__intrinsic__': 40.96000000000001
//             },
//             'November': {
//               'Alpha': 31.93848796297044,
//               'November': 9.69674914443835,
//               'Zulu': 15.751919031542137,
//               '__intrinsic__': 40.96000000000001
//             },
//             'Zulu': {
//               'Alpha': 17.24868523784603,
//               'November': 31.02763297113899,
//               'Zulu': 13.17771323721087,
//               '__intrinsic__': 40.96000000000001
//             }
//           },
//           groupMembers: {'Alpha', 'November', 'Zulu'},
//           playerTokens: 6,
//           tokensGiven: {'Alpha': 3.0, 'November': 2.0, 'Zulu': 1.0},
//           tokensReceived: {'Alpha': 3.0, 'November': 2.0, 'Zulu': -6.0},
//           colorGroups: {'Alpha': null, 'November': null, 'Zulu': null}),
//       popularities: {
//         1: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0},
//         2: {'Alpha': 111.16666666666667, 'November': 109.16666666666667, 'Zulu': 93.0},
//         3: {'Alpha': 126.30791371158395, 'November': 108.09271867612296, 'Zulu': 93.7306619385343},
//         4: {'Alpha': 139.08557997324937, 'November': 107.79018785456995, 'Zulu': 89.24655836088674},
//         5: {'Alpha': 127.28532453772095, 'November': 98.34715613895094, 'Zulu': 102.41403144619589}
//       },
//       networkGraph: const NetworkGraph(edges: [], nodes: []),
//       networkGraph3d: const NetworkGraph3d(edges: [], nodes: []));

//   await agent.nextRound(currentRound, playerName, gameParams);

//   currentRound = RoundState(
//       info: PlayerRoundInfo(
//           status: GameStatus.started,
//           round: 6,
//           endTime: DateTime.now(),
//           governmentRoundInfo: const GovernmentRoundInfo(round: 0),
//           playerName: 'Alpha',
//           playerLabels: {'Alpha': {}, 'November': {}, 'Zulu': {}},
//           playerPopularities: {
//             'Alpha': 131.4436638997309,
//             'November': 108.36176693735422,
//             'Zulu': 96.4990375600092
//           },
//           playerInfluences: {
//             'Alpha': {
//               'Alpha': 52.006263056831074,
//               'November': 36.72604262706581,
//               'Zulu': 9.94335821583401,
//               '__intrinsic__': 32.76800000000001
//             },
//             'November': {
//               'Alpha': 24.720127908651012,
//               'November': 10.62268866063343,
//               'Zulu': 40.25095036806977,
//               '__intrinsic__': 32.76800000000001
//             },
//             'Zulu': {
//               'Alpha': 13.352152947205116,
//               'November': 36.80829159852826,
//               'Zulu': 13.570593014275822,
//               '__intrinsic__': 32.76800000000001
//             }
//           },
//           groupMembers: {'Alpha', 'November', 'Zulu'},
//           playerTokens: 6,
//           tokensGiven: {'Alpha': 6.0, 'November': 0.0, 'Zulu': 0.0},
//           tokensReceived: {'Alpha': 6.0, 'November': 2.0, 'Zulu': 0.0},
//           colorGroups: {'Alpha': null, 'November': null, 'Zulu': null}),
//       popularities: {
//         1: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0},
//         2: {'Alpha': 111.16666666666667, 'November': 109.16666666666667, 'Zulu': 93.0},
//         3: {'Alpha': 126.30791371158395, 'November': 108.09271867612296, 'Zulu': 93.7306619385343},
//         4: {'Alpha': 139.08557997324937, 'November': 107.79018785456995, 'Zulu': 89.24655836088674},
//         5: {'Alpha': 127.28532453772095, 'November': 98.34715613895094, 'Zulu': 102.41403144619589},
//         6: {'Alpha': 131.4436638997309, 'November': 108.36176693735422, 'Zulu': 96.4990375600092}
//       },
//       networkGraph: const NetworkGraph(edges: [], nodes: []),
//       networkGraph3d: const NetworkGraph3d(edges: [], nodes: []));

//   await agent.nextRound(currentRound, playerName, gameParams);

//   currentRound = RoundState(
//       info: PlayerRoundInfo(
//           status: GameStatus.started,
//           round: 7,
//           endTime: DateTime.now(),
//           governmentRoundInfo: const GovernmentRoundInfo(round: 0),
//           playerName: 'Alpha',
//           playerLabels: {'Alpha': {}, 'November': {}, 'Zulu': {}},
//           playerPopularities: {
//             'Alpha': 141.06747082229114,
//             'November': 110.85535693126197,
//             'Zulu': 95.96992611497001
//           },
//           playerInfluences: {
//             'Alpha': {
//               'Alpha': 66.73221987165911,
//               'November': 39.82571535546773,
//               'Zulu': 8.295135595164286,
//               '__intrinsic__': 26.21440000000001
//             },
//             'November': {
//               'Alpha': 19.849224359244403,
//               'November': 8.805080705233621,
//               'Zulu': 55.98665186678393,
//               '__intrinsic__': 26.21440000000001
//             },
//             'Zulu': {
//               'Alpha': 10.721053106065945,
//               'November': 49.297577299803194,
//               'Zulu': 9.73689570910085,
//               '__intrinsic__': 26.21440000000001
//             }
//           },
//           groupMembers: {'Alpha', 'November', 'Zulu'},
//           playerTokens: 6,
//           tokensGiven: {'Alpha': 6.0, 'November': 0.0, 'Zulu': 0.0},
//           tokensReceived: {'Alpha': 6.0, 'November': 2.0, 'Zulu': 0.0},
//           colorGroups: {'Alpha': null, 'November': null, 'Zulu': null}),
//       popularities: {
//         1: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0},
//         2: {'Alpha': 111.16666666666667, 'November': 109.16666666666667, 'Zulu': 93.0},
//         3: {'Alpha': 126.30791371158395, 'November': 108.09271867612296, 'Zulu': 93.7306619385343},
//         4: {'Alpha': 139.08557997324937, 'November': 107.79018785456995, 'Zulu': 89.24655836088674},
//         5: {'Alpha': 127.28532453772095, 'November': 98.34715613895094, 'Zulu': 102.41403144619589},
//         6: {'Alpha': 131.4436638997309, 'November': 108.36176693735422, 'Zulu': 96.4990375600092},
//         7: {'Alpha': 141.06747082229114, 'November': 110.85535693126197, 'Zulu': 95.96992611497001}
//       },
//       networkGraph: const NetworkGraph(edges: [], nodes: []),
//       networkGraph3d: const NetworkGraph3d(edges: [], nodes: []));

//   await agent.nextRound(currentRound, playerName, gameParams);

//   currentRound = RoundState(
//       info: PlayerRoundInfo(
//           status: GameStatus.started,
//           round: 8,
//           endTime: DateTime.now(),
//           governmentRoundInfo: const GovernmentRoundInfo(round: 0),
//           playerName: 'Alpha',
//           playerLabels: {'Alpha': {}, 'November': {}, 'Zulu': {}},
//           playerPopularities: {
//             'Alpha': 127.38942455024748,
//             'November': 125.28010639168504,
//             'Zulu': 111.07721478702331
//           },
//           playerInfluences: {
//             'Alpha': {
//               'Alpha': 67.792872989813,
//               'November': 31.68496381516229,
//               'Zulu': 6.940067745272177,
//               '__intrinsic__': 20.97152000000001
//             },
//             'November': {
//               'Alpha': 28.40715699564634,
//               'November': 7.0050130349033495,
//               'Zulu': 68.89641636113534,
//               '__intrinsic__': 20.97152000000001
//             },
//             'Zulu': {
//               'Alpha': 14.85216781015806,
//               'November': 68.04140946929833,
//               'Zulu': 7.212117507566903,
//               '__intrinsic__': 20.97152000000001
//             }
//           },
//           groupMembers: {'Alpha', 'November', 'Zulu'},
//           playerTokens: 6,
//           tokensGiven: {'Alpha': 3.0, 'November': 2.0, 'Zulu': 1.0},
//           tokensReceived: {'Alpha': 3.0, 'November': 0.0, 'Zulu': 0.0},
//           colorGroups: {'Alpha': null, 'November': null, 'Zulu': null}),
//       popularities: {
//         1: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0},
//         2: {'Alpha': 111.16666666666667, 'November': 109.16666666666667, 'Zulu': 93.0},
//         3: {'Alpha': 126.30791371158395, 'November': 108.09271867612296, 'Zulu': 93.7306619385343},
//         4: {'Alpha': 139.08557997324937, 'November': 107.79018785456995, 'Zulu': 89.24655836088674},
//         5: {'Alpha': 127.28532453772095, 'November': 98.34715613895094, 'Zulu': 102.41403144619589},
//         6: {'Alpha': 131.4436638997309, 'November': 108.36176693735422, 'Zulu': 96.4990375600092},
//         7: {'Alpha': 141.06747082229114, 'November': 110.85535693126197, 'Zulu': 95.96992611497001},
//         8: {'Alpha': 127.38942455024748, 'November': 125.28010639168504, 'Zulu': 111.07721478702331}
//       },
//       networkGraph: const NetworkGraph(edges: [], nodes: []),
//       networkGraph3d: const NetworkGraph3d(edges: [], nodes: []));

//   await agent.nextRound(currentRound, playerName, gameParams);

//   currentRound = RoundState(
//       info: PlayerRoundInfo(
//           status: GameStatus.started,
//           round: 9,
//           endTime: DateTime.now(),
//           governmentRoundInfo: const GovernmentRoundInfo(round: 0),
//           playerName: 'Alpha',
//           playerLabels: {'Alpha': {}, 'November': {}, 'Zulu': {}},
//           playerPopularities: {
//             'Alpha': 131.53409037710958,
//             'November': 136.8470234524169,
//             'Zulu': 113.45303680508675
//           },
//           playerInfluences: {
//             'Alpha': {
//               'Alpha': 62.56861900658359,
//               'November': 42.64975849145361,
//               'Zulu': 9.538496879072351,
//               '__intrinsic__': 16.77721600000001
//             },
//             'November': {
//               'Alpha': 32.18773802602726,
//               'November': 5.829807579849984,
//               'Zulu': 82.05226184653964,
//               '__intrinsic__': 16.77721600000001
//             },
//             'Zulu': {
//               'Alpha': 16.57820490939147,
//               'November': 72.91836342417473,
//               'Zulu': 7.179252471520541,
//               '__intrinsic__': 16.77721600000001
//             }
//           },
//           groupMembers: {'Alpha', 'November', 'Zulu'},
//           playerTokens: 6,
//           tokensGiven: {'Alpha': 3.0, 'November': 2.0, 'Zulu': 1.0},
//           tokensReceived: {'Alpha': 3.0, 'November': 3.0, 'Zulu': 1.0},
//           colorGroups: {'Alpha': null, 'November': null, 'Zulu': null}),
//       popularities: {
//         1: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0},
//         2: {'Alpha': 111.16666666666667, 'November': 109.16666666666667, 'Zulu': 93.0},
//         3: {'Alpha': 126.30791371158395, 'November': 108.09271867612296, 'Zulu': 93.7306619385343},
//         4: {'Alpha': 139.08557997324937, 'November': 107.79018785456995, 'Zulu': 89.24655836088674},
//         5: {'Alpha': 127.28532453772095, 'November': 98.34715613895094, 'Zulu': 102.41403144619589},
//         6: {'Alpha': 131.4436638997309, 'November': 108.36176693735422, 'Zulu': 96.4990375600092},
//         7: {'Alpha': 141.06747082229114, 'November': 110.85535693126197, 'Zulu': 95.96992611497001},
//         8: {
//           'Alpha': 127.38942455024748,
//           'November': 125.28010639168504,
//           'Zulu': 111.07721478702331
//         },
//         9: {'Alpha': 131.53409037710958, 'November': 136.8470234524169, 'Zulu': 113.45303680508675}
//       },
//       networkGraph: const NetworkGraph(edges: [], nodes: []),
//       networkGraph3d: const NetworkGraph3d(edges: [], nodes: []));

//   await agent.nextRound(currentRound, playerName, gameParams);

//   currentRound = RoundState(
//       info: PlayerRoundInfo(
//           status: GameStatus.started,
//           round: 10,
//           endTime: DateTime.now(),
//           governmentRoundInfo: const GovernmentRoundInfo(round: 0),
//           playerName: 'Alpha',
//           playerLabels: {'Alpha': {}, 'November': {}, 'Zulu': {}},
//           playerPopularities: {
//             'Alpha': 128.8286295120531,
//             'November': 144.45251587989748,
//             'Zulu': 127.09811285533974
//           },
//           playerInfluences: {
//             'Alpha': {
//               'Alpha': 62.15864487605255,
//               'November': 40.754884768675275,
//               'Zulu': 12.4933270673253,
//               '__intrinsic__': 13.421772800000006
//             },
//             'November': {
//               'Alpha': 36.946486277005164,
//               'November': 4.761836257692697,
//               'Zulu': 89.32242054519959,
//               '__intrinsic__': 13.421772800000006
//             },
//             'Zulu': {
//               'Alpha': 18.85784539557388,
//               'November': 89.20350581390721,
//               'Zulu': 5.614988845858651,
//               '__intrinsic__': 13.421772800000006
//             }
//           },
//           groupMembers: {'Alpha', 'November', 'Zulu'},
//           playerTokens: 6,
//           tokensGiven: {'Alpha': 3.0, 'November': 2.0, 'Zulu': 1.0},
//           tokensReceived: {'Alpha': 3.0, 'November': 1.0, 'Zulu': 1.0},
//           colorGroups: {'Alpha': null, 'November': null, 'Zulu': null}),
//       popularities: {
//         1: {'Alpha': 100.0, 'November': 100.0, 'Zulu': 100.0},
//         2: {'Alpha': 111.16666666666667, 'November': 109.16666666666667, 'Zulu': 93.0},
//         3: {'Alpha': 126.30791371158395, 'November': 108.09271867612296, 'Zulu': 93.7306619385343},
//         4: {'Alpha': 139.08557997324937, 'November': 107.79018785456995, 'Zulu': 89.24655836088674},
//         5: {'Alpha': 127.28532453772095, 'November': 98.34715613895094, 'Zulu': 102.41403144619589},
//         6: {'Alpha': 131.4436638997309, 'November': 108.36176693735422, 'Zulu': 96.4990375600092},
//         7: {'Alpha': 141.06747082229114, 'November': 110.85535693126197, 'Zulu': 95.96992611497001},
//         8: {
//           'Alpha': 127.38942455024748,
//           'November': 125.28010639168504,
//           'Zulu': 111.07721478702331
//         },
//         9: {'Alpha': 131.53409037710958, 'November': 136.8470234524169, 'Zulu': 113.45303680508675},
//         10: {'Alpha': 128.8286295120531, 'November': 144.45251587989748, 'Zulu': 127.09811285533974}
//       },
//       networkGraph: const NetworkGraph(edges: [], nodes: []),
//       networkGraph3d: const NetworkGraph3d(edges: [], nodes: []));

//   await agent.nextRound(currentRound, playerName, gameParams);
// }
