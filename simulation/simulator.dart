// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

// ignore: unused_import
import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
// import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';

import 'package:jhg_core/jhg_core.dart';
import './providers.dart';

List<Completer<List<PopularityMetrics>>> completers = [];

void main(List<String> args) async {
  print('${DateTime.now()} running simulator...');
  print('${args[1]}_${args[0]}');

  const timeout = Duration(minutes: 5, seconds: 30);
  const popSize = 100;
  const numGeneCopies = 1;
  const numGens = 200;
  const gamesPerGen = 100;
  const agentsPerGame = 8;
  const roundsPerGame = 30;

  const numCats = 2;
  final extraAgents = [for (int i = 0; i < numCats; i++) CatAgent.new];

  if (args[1] == 'noFearNoChat') {
    final lastSuccessfulGen = lastSucccessfulGeneration(
        'results_withCats_SChMUSR_noFear_noChat_${args[0]}', numGens);

    await evolve(
        popSize: popSize,
        numGeneCopies: numGeneCopies,
        startIndex: lastSuccessfulGen,
        numGens: numGens,
        gamesPerGen: gamesPerGen,
        agentsPerGame: agentsPerGame,
        roundsPerGame: roundsPerGame,
        povertyLine: 0,
        varied: false,
        chat: false,
        useSChMUSR: false,
        folder: '../results/results_withCats_SChMUSR_noFear_noChat_${args[0]}',
        timeout: timeout,
        extraAgents: extraAgents);
  } else if (args[1] == 'noFearNoChatNotCAB') {
    final lastSuccessfulGen = lastSucccessfulGeneration(
        'results_withCats_SChMUSR_notCAB_noFear_noChat_${args[0]}', numGens);

    await evolve(
        popSize: popSize,
        numGeneCopies: numGeneCopies,
        startIndex: lastSuccessfulGen,
        numGens: numGens,
        gamesPerGen: gamesPerGen,
        agentsPerGame: agentsPerGame,
        roundsPerGame: roundsPerGame,
        povertyLine: 0,
        varied: false,
        chat: false,
        useSChMUSR: true,
        useFear: false,
        folder:
            '../results/results_withCats_SChMUSR_notCAB_noFear_noChat_${args[0]}',
        timeout: timeout,
        extraAgents: extraAgents);
  } else if (args[1] == 'fearNoChat') {
    final lastSuccessfulGen = lastSucccessfulGeneration(
        'results_withCats_SChMUSR_fear_noChat_${args[0]}', numGens);

    await evolve(
        popSize: popSize,
        numGeneCopies: numGeneCopies,
        startIndex: lastSuccessfulGen,
        numGens: numGens,
        gamesPerGen: gamesPerGen,
        agentsPerGame: agentsPerGame,
        roundsPerGame: roundsPerGame,
        povertyLine: 0,
        varied: false,
        chat: false,
        useSChMUSR: true,
        folder: '../results/results_withCats_SChMUSR_fear_noChat_${args[0]}',
        timeout: timeout,
        extraAgents: extraAgents);
  } else if (args[1] == 'noFearChat') {
    final lastSuccessfulGen = lastSucccessfulGeneration(
        'results_withCats_SChMUSR_noFear_chat_${args[0]}', numGens);

    await evolve(
        popSize: popSize,
        numGeneCopies: numGeneCopies,
        startIndex: lastSuccessfulGen,
        numGens: numGens,
        gamesPerGen: gamesPerGen,
        agentsPerGame: agentsPerGame,
        roundsPerGame: roundsPerGame,
        povertyLine: 0,
        varied: false,
        chat: true,
        useSChMUSR: true,
        useFear: false,
        folder: '../results/results_withCats_SChMUSR_noFear_chat_${args[0]}',
        timeout: timeout,
        extraAgents: extraAgents);
  } else if (args[1] == 'fearChat') {
    final lastSuccessfulGen = lastSucccessfulGeneration(
        'results_withCats_SChMUSR_fear_chat_${args[0]}', numGens);

    await evolve(
        popSize: popSize,
        numGeneCopies: numGeneCopies,
        startIndex: lastSuccessfulGen,
        numGens: numGens,
        gamesPerGen: gamesPerGen,
        agentsPerGame: agentsPerGame,
        roundsPerGame: roundsPerGame,
        povertyLine: 0,
        varied: false,
        chat: true,
        useSChMUSR: true,
        folder: '../results/results_withCats_SChMUSR_fear_chat_${args[0]}',
        timeout: timeout,
        extraAgents: extraAgents);
  } else if (args[1] == 'eCAB') {
    final lastSuccessfulGen =
        lastSucccessfulGeneration('results_withCats_eCAB_${args[0]}', numGens);

    await evolve(
      popSize: popSize,
      numGeneCopies: numGeneCopies,
      startIndex: lastSuccessfulGen,
      numGens: numGens,
      gamesPerGen: gamesPerGen,
      agentsPerGame: agentsPerGame,
      roundsPerGame: roundsPerGame,
      povertyLine: 0,
      varied: false,
      chat: false,
      useSChMUSR: false,
      folder: '../results/results_withCats_eCAB_${args[0]}',
      timeout: timeout,
      extraAgents: extraAgents,
      useMinKeep: true,
    );
  }

  exit(0);
}

int lastSucccessfulGeneration(String folder, int numGenerations) {
  try {
    final files = Directory('./$folder/generations').listSync()
      ..sort((a, b) {
        final aNum =
            int.parse(RegExp(r'_(\d+)\.csv').firstMatch(a.path)!.group(1)!);
        final bNum =
            int.parse(RegExp(r'_(\d+)\.csv').firstMatch(b.path)!.group(1)!);
        return aNum.compareTo(bNum);
      });

    final lastSuccessfulGen = int.parse(
        RegExp(r'_(\d+)\.csv').firstMatch(files.last.path)?.group(1) ?? '0');

    if (lastSuccessfulGen == numGenerations - 1) {
      print('Already completed');
      exit(0);
    }

    print('Starting from generation $lastSuccessfulGen');

    return lastSuccessfulGen;
  } catch (_) {
    return 0;
  }
}

Future<void> initialize() async {
  const dir = '/home/melissa/Documents/.jhg_data/preprod/emulator';
  final d = Directory(dir);
  if (!d.existsSync()) {
    d.createSync(recursive: true);
  }
  setupDartFirebaseStorage(d);

  // await initFirebase();
}

Future<void> evolve({
  required int popSize,
  required int numGeneCopies,
  required int startIndex,
  required int numGens,
  required int gamesPerGen,
  required int agentsPerGame,
  required int roundsPerGame,
  required double povertyLine,
  required bool varied,
  required bool chat,
  required bool useSChMUSR,
  bool useFear = true,
  required String folder,
  Duration timeout = const Duration(minutes: 2, seconds: 30),
  List<Agent Function(AutoDisposeProviderRef<dynamic>)>? extraAgents,
  bool useMinKeep = false,
}) async {
  final start = DateTime.now();

  var theGenePools = <GeneMetrics>[];
  var theGenePoolsOld = <GeneMetrics>[];

  if (startIndex == 0) {
    for (var j = 0; j < popSize; j++) {
      theGenePools.add(GeneMetrics(randomGeneString(numGeneCopies)));
    }
  } else {
    final file = File('./$folder/generations/gen_${startIndex - 1}.csv');
    if (!file.existsSync()) {
      throw Exception('File does not exist: ${file.path}');
    }

    final csv =
        const CsvToListConverter().convert(file.readAsStringSync(), eol: '\n');

    for (var j = 0; j < popSize; j++) {
      final gene = csv[j][0] as String;
      final count = csv[j][1] as int;
      final relFit = csv[j][2] as double;
      final absFit = csv[j][3] as double;
      final metric = GeneMetrics(gene,
          count: count, absoluteFitness: absFit, relativeFitness: relFit);
      theGenePoolsOld.add(metric);
    }

    theGenePools = evolvePopulationPairs(
        theGenePoolsOld, popSize, numGeneCopies, useMinKeep);
  }

  //TODO: set up initial popularities
  // final possibleInitPops = {'equal', 'random', 'step', 'power', 'highlow'};

  // let's do this for each generation
  for (var gen = startIndex; gen < numGens; gen++) {
    final genStart = DateTime.now();
    completers.clear();

    // let's do this for each game
    for (var game = 0; game < gamesPerGen; game++) {
      final agents = <GeneMetrics>[];
      final plyrIdxs = <int>[];

      // time to pick individuals from the gene pools
      for (var i = 0; i < agentsPerGame; i++) {
        plyrIdxs.add(Random().nextInt(popSize));
        agents.add(theGenePools[plyrIdxs[i]]);
      }

      // print('$gen-$game');

      // final int sel;
      // if (varied) {
      //   sel = Random().nextInt(5);
      // } else {
      //   sel = 0;
      // }
      // defineInitialPopularities(possibleInitPops[sel], numPlayers, initialPopularities);

      // record who the players were
      await Directory('./$folder/players/gen_$gen').create(recursive: true);
      final resultsFile =
          File('./$folder/players/gen_$gen/players_${gen}_$game.txt');

      if (resultsFile.existsSync()) {
        await resultsFile.delete();
      }
      for (final player in plyrIdxs) {
        await resultsFile.writeAsString(
            '$player ${theGenePools[player].gene}\n',
            mode: FileMode.append); //TODO: write initial pop too
      }

      completers.add(Completer<List<PopularityMetrics>>());

      //Run games for each generation concurrently on separate isolates
      // unawaited(Isolate.run(() =>

      //     // getAlgorithmTestData(
      //     // [for (int i = 0; i < agentsPerGame; i++) theGenePools[plyrIdxs[i]].gene])

      //     playGame(
      //       [
      //         for (int i = 0; i < agentsPerGame; i++)
      //           Provider.autoDispose(
      //               (ref) => ChatterBotAgent(ref,
      //                   genes: theGenePools[plyrIdxs[i]].gene, numGeneCopies: numGeneCopies),
      //               dependencies: [...agentProviders])
      //       ],
      //       agentsPerGame,
      //       roundsPerGame,
      //       gen,
      //       game,
      //       {}, // `TODO`: initialPopularities
      //       0,
      //       false,
      //       chat,
      //     )).then((pMetrics) {
      //   for (var i = 0; i < agentsPerGame; i++) {
      //     final gene = theGenePools[plyrIdxs[i]].gene;
      //     final pmGene = pMetrics[i].gene;
      //     if (gene != pmGene) {
      //       print('gene mismatch: $gene != $pmGene');
      //     }

      //     //Update fitness
      //     theGenePools[plyrIdxs[i]].count++;
      //     theGenePools[plyrIdxs[i]].absoluteFitness +=
      //         (pMetrics[i].avePop + pMetrics[i].endPop) / 2.0;
      //     theGenePools[plyrIdxs[i]].relativeFitness += pMetrics[i].relPop;
      //   }

      //   completers[game].complete(pMetrics);
      // }).timeout(
      //   const Duration(minutes: 2),
      //   onTimeout: () {
      //     print('Isolate timed out on $gen-$game');
      //     completers[game].complete([]);
      //   },

      //   // ignore: avoid_types_on_closure_parameters
      // ).catchError((Object error) {
      //   print('caught error: ${error.runtimeType}: $error');
      //   completers[game].complete([]);
      // }));

      // create port to listen for popularity metrics from the isolate
      final port = ReceivePort();
      port.listen((pMetrics) {
        if (pMetrics is List<PopularityMetrics>) {
          for (var i = 0; i < agentsPerGame; i++) {
            final gene = theGenePools[plyrIdxs[i]].gene;
            final pmGene = pMetrics[i].gene;
            if (gene != pmGene) {
              print('gene mismatch: $gene != $pmGene');
            }

            //Update fitness
            theGenePools[plyrIdxs[i]].count++;
            theGenePools[plyrIdxs[i]].absoluteFitness +=
                (pMetrics[i].avePop + pMetrics[i].endPop) / 2.0;
            theGenePools[plyrIdxs[i]].relativeFitness += pMetrics[i].relPop;
          }

          completers[game].complete(pMetrics);
          port.close();
        }
      });

      // spawn isolate to run game
      final isolate = runIsolate(
          theGenePools,
          plyrIdxs,
          numGeneCopies,
          agentsPerGame,
          roundsPerGame,
          gen,
          game,
          chat,
          port.sendPort,
          folder,
          extraAgents,
          useSChMUSR,
          useFear);

      // kill the isolate if it takes too long
      unawaited(completers[game].future.timeout(timeout, onTimeout: () async {
        print('Isolate timed out on $gen-$game');
        (await isolate).kill(priority: Isolate.immediate);
        print('Isolate killed');
        if (!completers[game].isCompleted) {
          completers[game].complete([]);
        }
        return [];
      }));
      //END isolate experiment
    }

    // wait for all games in this generation to finish
    for (final completer in completers) {
      await completer.future;
    }

    for (var i = 0; i < popSize; i++) {
      if (theGenePools[i].count > 0) {
        theGenePools[i].relativeFitness /= theGenePools[i].count;
        theGenePools[i].absoluteFitness /= theGenePools[i].count;
      } else {
        theGenePools[i].relativeFitness = 0.0;
        theGenePools[i].absoluteFitness = 0.0;
      }
    }
    theGenePools.sort(compareEm);

    await writeGenerationResults(
        theGenePools, popSize, gen, agentsPerGame, folder);

    //evolve population
    theGenePoolsOld = theGenePools;
    theGenePools = evolvePopulationPairs(
        theGenePoolsOld, popSize, numGeneCopies, useMinKeep);

    final genTime = DateTime.now().difference(genStart);
    final totalTime = DateTime.now().difference(start);
    final etl = Duration(
        microseconds: ((numGens - gen - 1) *
                totalTime.inMicroseconds /
                ((gen - startIndex + 1) > 0 ? (gen - startIndex + 1) : 1))
            .round());
    print(
        '${DateTime.now()} time taken to run generation $gen with $gamesPerGen games: $genTime - total time: $totalTime - estimated time left: $etl');
    // write this to the log file
    await Directory('./$folder/logs').create(recursive: true);
    final logFile = File('./$folder/logs/time_log.txt');
    await logFile.writeAsString(
        '${DateTime.now()} time taken to run generation $gen with $gamesPerGen games: $genTime - total time: $totalTime - estimated time left: $etl\n',
        mode: FileMode.append);

    // Kill the program if it's finished
    if (gen == numGens - 1) {
      print('done');
      return;
    }
  }
}

Future<Isolate> runIsolate(
  List<GeneMetrics> theGenePools,
  List<int> plyrIdxs,
  int numGeneCopies,
  int agentsPerGame,
  int roundsPerGame,
  int gen,
  int game,
  bool chat,
  SendPort sendPort,
  String folder,
  List<Agent Function(AutoDisposeProviderRef)>? extraAgents,
  bool useSChMUSR,
  bool useFear,
) async {
  await Directory('./$folder/logs/gen_$gen').create(recursive: true);
  final logFile = File('./$folder/logs/gen_$gen/gameLog_${gen}_$game.txt');
  if (logFile.existsSync()) {
    await logFile.delete();
  }

  final isolate = Isolate.spawn<SendPort>((sendPort) async {
    final List<AutoDisposeProvider<GeneAgent>> agents;

    if (useSChMUSR) {
      agents = [
        for (int i = 0; i < agentsPerGame; i++)
          Provider.autoDispose(
              (ref) => ChatterBotAgent(ref,
                  genes: theGenePools[plyrIdxs[i]].gene,
                  numGeneCopies: numGeneCopies,
                  useFear: useFear,
                  logfile: logFile),
              dependencies: [...agentProviders])
      ];
    } else {
      agents = [
        for (int i = 0; i < agentsPerGame; i++)
          Provider.autoDispose(
              (ref) => GeneAgent(
                    ref,
                    genes: theGenePools[plyrIdxs[i]].gene,
                    numGeneCopies: numGeneCopies,
                  ),
              dependencies: [...agentProviders])
      ];
    }

    final extraAgentProviders = [
      for (final agent
          in extraAgents ?? <Agent Function(AutoDisposeProviderRef<dynamic>)>[])
        Provider.autoDispose(agent, dependencies: [...agentProviders])
    ];

    final results = await playGame(
      agents,
      agentsPerGame + (extraAgents?.length ?? 0),
      roundsPerGame,
      gen,
      game,
      {}, // `TODO: initialPopularities
      0,
      false,
      chat,
      folder,
      extraAgentProviders,
    );

    Isolate.exit(sendPort, results);
  }, sendPort);

  return isolate;
}

List<PopularityMetrics> getAlgorithmTestData(List<String> genes) {
  final metrics = <PopularityMetrics>[];
  for (final gene in genes) {
    final values = gene.split('_');
    values.removeAt(0);
    final fitness = values.map(int.parse).toList().sum.toDouble();
    final metric = PopularityMetrics(gene, fitness, fitness, fitness);
    metrics.add(metric);
  }

  var sumOfPops = 0.0;
  for (var i = 0; i < genes.length; i++) {
    sumOfPops += metrics[i].avePop;
  }
  for (var i = 0; i < genes.length; i++) {
    metrics[i].relPop = metrics[i].avePop / sumOfPops;
  }

  return metrics;
}

List<GeneMetrics> evolvePopulationPairs(List<GeneMetrics> theGenePoolsOld,
    int popSize, int numGeneCopies, bool useMinKeep) {
  final theNewGenePool = <GeneMetrics>[];
  for (var i = 0; i < popSize; i++) {
    // select 2 agents from theGenePoolsOld[pool]
    int ind1, ind2;
    if (i < (popSize / 5.0)) {
      ind1 = selectByFitness(theGenePoolsOld, popSize, true);
      ind2 = selectByFitness(theGenePoolsOld, popSize, false);
    } else {
      ind1 = selectByFitness(theGenePoolsOld, popSize, false);
      ind2 = selectByFitness(theGenePoolsOld, popSize, false);
    }

    var geneStr = 'genes_';

    final ind1Genes = theGenePoolsOld[ind1].gene.split('_');
    final ind2Genes = theGenePoolsOld[ind2].gene.split('_');
    // remove the first element which is 'genes'
    ind1Genes.removeAt(0);
    ind2Genes.removeAt(0);

    for (var g = 0; g < theGenePoolsOld[0].numGenes; g++) {
      if (!useMinKeep) {
        const minKeepIdx = 12;
        if (g == minKeepIdx) {
          geneStr += '0';
          if (g < (theGenePoolsOld[0].numGenes - 1)) {
            geneStr += '_';
          }
          continue;
        }
      }

      if (Random().nextBool()) {
        geneStr += mutateIt(int.parse(ind1Genes[g])).toString();
        if (g < (theGenePoolsOld[0].numGenes - 1)) {
          geneStr += '_';
        }
      } else {
        geneStr += mutateIt(int.parse(ind2Genes[g])).toString();
        if (g < (theGenePoolsOld[0].numGenes - 1)) {
          geneStr += '_';
        }
      }
    }

    theNewGenePool.add(GeneMetrics(geneStr));
    // theNewGenePool.add(GeneMetrics(theGenePoolsOld[ind1].gene));
  }

  return theNewGenePool;
}

int selectByFitness(List<GeneMetrics> thePopulation, int popSize, bool rank) {
  var mag = 0.0;
  for (var i = 0; i < popSize; i++) {
    if (rank) {
      mag += thePopulation[i].relativeFitness;
    } else {
      mag += thePopulation[i].absoluteFitness;
    }
  }

  final num = Random().nextDouble();
  var sum = 0.0;
  for (var i = 0; i < popSize; i++) {
    if (rank) {
      sum += thePopulation[i].relativeFitness / mag;
    } else {
      sum += thePopulation[i].absoluteFitness / mag;
    }

    if (num <= sum) {
      return i;
    }
  }

  throw Exception("didn't select; num = $num; sum = $sum\n");
}

int mutateIt(int gene) {
  final v = Random().nextInt(100);
  if (v >= 15) {
    return gene;
  } else if (v < 3) {
    return Random().nextInt(101);
  } else {
    var g = gene + (Random().nextInt(11)) - 5;
    if (g < 0) {
      g = 0;
    }
    if (g > 100) {
      g = 100;
    }
    return g;
  }
}

Future<void> writeGenerationResults(List<GeneMetrics> theGenePools, int popSize,
    int gen, int agentsPerGame, String folder) async {
  await Directory('./$folder/generations').create(recursive: true);
  final resultsFile = File('./$folder/generations/gen_$gen.csv');
  if (resultsFile.existsSync()) {
    await resultsFile.delete();
  }

  for (var i = 0; i < popSize; i++) {
    await resultsFile.writeAsString(
        '${theGenePools[i].gene},${theGenePools[i].count},${theGenePools[i].relativeFitness},${theGenePools[i].absoluteFitness},${getCSVFormattedGeneString(theGenePools[i].gene)}\n',
        mode: FileMode.append);
  }
}

String getCSVFormattedGeneString(String gene) {
  final genes = gene.split('_');
  genes.removeAt(0);
  return genes.join(',');
}

int compareEm(GeneMetrics a, GeneMetrics b) {
  return a.absoluteFitness.compareTo(b.absoluteFitness);
}

Genes randomGenes() {
  final random = Random();
  final genes = Genes(
    visualTrait: random.nextInt(101),
    alpha: random.nextInt(101),
    homophily: random.nextInt(101),
    otherishDebtLimits: random.nextInt(101),
    coalitionTarget: random.nextInt(101),
    fixedUsage: random.nextInt(101),
    wModularity: random.nextInt(101),
    wCentrality: random.nextInt(101),
    wCollectiveStrength: random.nextInt(101),
    wFamiliarity: random.nextInt(101),
    wProsocial: random.nextInt(101),
    initialDefense: random.nextInt(101),
    minKeep: random.nextInt(101),
    defenseUpdate: random.nextInt(101),
    defensePropensity: random.nextInt(101),
    fearDefense: random.nextInt(101),
    safetyFirst: random.nextInt(101),
    pillageFury: random.nextInt(101),
    pillageDelay: random.nextInt(101),
    pillagePriority: random.nextInt(101),
    pillageMargin: random.nextInt(101),
    pillageCompanionship: random.nextInt(101),
    pillageFriends: random.nextInt(101),
    vengeanceMultiplier: random.nextInt(101),
    vengeanceMax: random.nextInt(101),
    vengeancePriority: random.nextInt(101),
    defendFriendMultiplier: random.nextInt(101),
    defendFriendMax: random.nextInt(101),
    defendFriendPriority: random.nextInt(101),
    attackGoodGuys: random.nextInt(101),
    limitingGive: random.nextInt(101),
    groupAware: random.nextInt(101),
    joinCoop: random.nextInt(101),
    trustRate: random.nextInt(101),
    distrustRate: random.nextInt(101),
    startingTrust: random.nextInt(101),
    wChatAgreement: random.nextInt(101),
    wTrust: random.nextInt(101),
    wAccusations: random.nextInt(101),
    fearAggression: random.nextInt(101),
    fearGrowth: random.nextInt(101),
    fearSize: random.nextInt(101),
    fearContagion: random.nextInt(101),
    fearThreshold: random.nextInt(101),
    fearPriority: random.nextInt(101),
  );

  return genes;
}

String randomGeneString(int numGeneCopies) {
  final genes = randomGenes();

  return genes.getGeneString(numGeneCopies,
      otherGenes: [for (var i = 0; i < numGeneCopies - 1; i++) randomGenes()]);
}

Future<List<PopularityMetrics>> playGame(
  List<AutoDisposeProvider<GeneAgent>> agents,
  int numPlayers,
  int numRounds,
  int gener,
  int gamer,
  Map<String, double> initialPopularities,
  double povertyLine,
  bool forcedRandom,
  bool chat,
  String folder,
  List<AutoDisposeProvider<Agent>>? extraAgents,
) async {
  await initialize();
  // final startItr = DateTime.now();

  await Directory('./$folder/gameInfos/gen_$gener').create(recursive: true);
  final resultsFile =
      File('./$folder/gameInfos/gen_$gener/gameInfo_${gener}_$gamer.json');

  await resultsFile.writeAsString('game started');

  //Set up game
  final gameParams = GameParams(
    lengthOfRound: const Duration(seconds: 30),
    gameEndCriteria: GameEndCriteria.rounds(low: numRounds, high: numRounds),
    popularityFunctionParams: PopularityFunctionParams(
      povertyLine: povertyLine,
    ),
    chatType: chat ? ChatType.direct : ChatType.none,
  );

  final gameService = InAppGameService();

  //TODO: get game setup working so we can use different initial popularities
  // final gameSetup = await createGameSetup(numRounds, povertyLine, initialPopularities);

  // final lobby = gameService.lobbyListen(
  //     LobbyRequest(gameId: createGameResponse.gameId, playerId: createGameResponse.playerId));

  // final listener = lobby.listen((event) async {
  //   if (event.lobby.numPlayers > 1 && !event.lobby.gameStarted) {
  //     final startGameResponse = await gameService.startGame(StartGameRequest(
  //       gameId: createGameResponse.gameId,
  //       playerId: createGameResponse.playerId,
  //     ));
  //     print(startGameResponse);
  //     completer.complete();
  //   }
  // });

  // final gameSetupResponse = await gameService.setGameSetup(SetGameSetupRequest(
  //     gameId: createGameResponse.gameId,
  //     playerId: createGameResponse.playerId,
  //     setup: const GameSetup(name: 'Simulation', id: '-NtqCURT9ZcBY7lfXYw2')));
  // print(gameSetupResponse);

  final ais = <ProviderContainer>[];
  final subs = <ProviderSubscription<GeneAgent>>[];

  final roundService = InAppRoundService();
  final dataService = InAppDataService();
  // const chatService = InAppChatService();

  //Create game and set gameParams
  final createGameResponse = await gameService.createGame(
      const CreateGameRequest(isObserver: true, playerName: 'Observer'));
  await gameService.updateGameParams(UpdateGameParamsRequest(
      gameId: createGameResponse.gameId,
      playerId: createGameResponse.playerId,
      params: gameParams));

  //Add gene agents to game
  for (var p = 0; p < agents.length; p++) {
    ais.add(ProviderContainer(
      overrides: [
        multiplayerIdProvider.overrideWithValue(100 + p),
        gameServiceProvider.overrideWithValue(gameService),
        isAdminProvider.overrideWith((ref) => false),
        isObserverProvider.overrideWith((ref) => false),
        ...persistenceTestOverrides
      ],
    ));
    subs.add(ais[p].listen(agents[p], (_, __) {}));
    final agent = subs[p].read();
    await agent.joinAndPlay(createGameResponse.gameCode,
        name: 'Agent with genes ${agent.genes}');
  }

  //Add extra agents to game
  final extraSubs = <ProviderSubscription<Agent>>[];

  if (extraAgents != null) {
    for (var p = 0; p < extraAgents.length; p++) {
      ais.add(ProviderContainer(
        overrides: [
          multiplayerIdProvider.overrideWithValue(100 + p + agents.length),
          gameServiceProvider.overrideWithValue(gameService),
          isAdminProvider.overrideWith((ref) => false),
          isObserverProvider.overrideWith((ref) => false),
          ...persistenceTestOverrides
        ],
      ));
      extraSubs.add(ais[p + agents.length].listen(extraAgents[p], (_, __) {}));
      final agent = extraSubs[p].read();
      await agent.joinAndPlay(createGameResponse.gameCode);
    }
  }

  //Start game
  await gameService.startGame(StartGameRequest(
      gameId: createGameResponse.gameId,
      playerId: createGameResponse.playerId));

  final gameCompleter = Completer<List<PopularityMetrics>>();

  // final watchChat = chatService.watchChat(WatchChatRequest(
  //     gameId: createGameResponse.gameId, playerId: createGameResponse.playerId, isObserver: true));

  // var chatCount = 0;
  // watchChat.listen((event) async {
  //   chatCount++;
  //   if (chatCount % 10 == 0) {
  //     final gameInfo =
  //         await dataService.download(DownloadRequest(gameCodes: [createGameResponse.gameCode]));

  //     await Directory('./results/gameInfos/gen_$gener').create(recursive: true);
  //     final resultsFile =
  //         File('./results/gameInfos/gen_$gener/gameInfo_${gener}_$gamer.json');

  //     await resultsFile.writeAsString(
  //       jsonEncode(gameInfo),
  //     );
  //   }
  // });

  //Watch for end of game and write the game info when completed
  final watchGame = roundService.watchGame(WatchGameRequest(
      gameId: createGameResponse.gameId,
      playerId: createGameResponse.playerId,
      isObserver: true));
  watchGame.listen((event) async {
    if (event.roundInfo.round % 5 == 0) {
      //  print('round ${event.roundInfo.round}');
    }
    if (event.roundInfo.status.isGameOver) {
      // print('Game over');

      final gameInfo = await dataService
          .download(DownloadRequest(gameCodes: [createGameResponse.gameCode]));

      await Directory('./$folder/gameInfos/gen_$gener').create(recursive: true);
      final resultsFile =
          File('./$folder/gameInfos/gen_$gener/gameInfo_${gener}_$gamer.json');

      await resultsFile.writeAsString(
        jsonEncode(gameInfo),
      );

      final agentNameToGene = [
        for (final sub in subs) (sub.read().myPlayerName, sub.read().genes!)
      ];

      final extraAgentNames = [
        for (final sub in extraSubs) sub.read().myPlayerName
      ];

      final lastRound = event.roundInfo.round - 1;
      final popularityMetrics = getPopularityMetrics(
          gameInfo, numPlayers, lastRound, agentNameToGene, extraAgentNames);

      gameCompleter.complete(popularityMetrics);
    }
  });

  // ignore: avoid_types_on_closure_parameters
  final pMetrics = await gameCompleter.future.catchError((Object error) {
    throw Exception('Game failed to complete: $error');
  });
  // final itrTime = DateTime.now().difference(startItr);
  // print('time taken: $itrTime');

  return pMetrics;
}

List<PopularityMetrics> getPopularityMetrics(
    DownloadResponse gameInfo,
    int numPlayers,
    int lastRound,
    List<(String, String)> agentNameToGene,
    List<String> extraAgentNames) {
  final pMetrics = <PopularityMetrics>[];
  final game = gameInfo.infos?[0];
  if (game == null) {
    throw Exception("Game info is null. Can't generate popularity metrics.");
  }

  for (final agent in agentNameToGene) {
    final lastRoundString = roundKey(lastRound.toString());

    final avePop =
        game.popularities!.entries.map((e) => e.value[agent.$1]!).average;
    final endPop = game.popularities![lastRoundString]![agent.$1]!;
    final gene = agent.$2;

    pMetrics.add(PopularityMetrics(gene, avePop, endPop, 0));
  }

  //Add pops of the extra agents
  var sumOfPops = 0.0;
  for (final extraAgent in extraAgentNames) {
    final avePop =
        game.popularities!.entries.map((e) => e.value[extraAgent]!).average;

    sumOfPops += avePop;
  }

  //TODO: is this supposed to be calculated with avePop or endPop?

  for (var i = 0; i < pMetrics.length; i++) {
    sumOfPops += pMetrics[i].avePop;
  }
  for (var i = 0; i < pMetrics.length; i++) {
    pMetrics[i].relPop = pMetrics[i].avePop / sumOfPops;
  }

  return pMetrics;
}

//No worky
Future<GameSetup> createGameSetup(
  int numRounds,
  double povertyLine,
  Map<String, double> initialPopularities,
) async {
  //Set up game
  final gameParams = GameParams(
    gameEndCriteria: GameEndCriteria.rounds(low: numRounds, high: numRounds),
    popularityFunctionParams: PopularityFunctionParams(
      povertyLine: povertyLine,
    ),
    chatType: ChatType.direct,
  );

  //Admin service to create game setup
  final adminService =
      FirebaseAdminService(Uri(scheme: 'http', host: 'localhost', port: 8080));
  print('signing in...');
  //TODO: get credentials working
  // final credentials = Credentials.applicationDefault()!;

  // final credentials = await dartFirebaseAuth.createUserWithEmailAndPassword(
  //     email: 'crandallberry.ai@gmail.com', password: 'crandallberrylim');
  final credentials = await dartFirebaseAuth.signInWithEmailAndPassword(
      email: 'crandallberry.ai@gmail.com', password: 'crandallberrylim');
  print('signed in');

  final authId = credentials.user?.uid;

  if (authId == null) {
    throw Exception('authId is null');
  }

  const gameSetup = GameSetup(name: 'simulation game');

  final uploadSetupResponse = await adminService.uploadSetup(UploadSetupRequest(
      authId: authId,
      game: InitialGameInfo(gameParams: gameParams),
      setup: gameSetup));

  if (uploadSetupResponse.success) {
    return gameSetup.copyWith(id: uploadSetupResponse.id);
  } else {
    throw Exception('Failed to upload game setup');
  }
}

class PopularityMetrics {
  PopularityMetrics(this.gene, this.avePop, this.endPop, this.relPop);

  String gene;
  double avePop;
  double endPop;
  double relPop;

  @override
  String toString() {
    return 'PopularityMetrics(avePop: $avePop, endPop: $endPop, relPop: $relPop, gene: $gene)';
  }
}

class GeneMetrics {
  GeneMetrics(this.gene,
      {this.count = 0, this.absoluteFitness = 0, this.relativeFitness = 0});

  String gene;
  int count;
  double absoluteFitness;
  double relativeFitness;

  int get numGenes => gene.split('_').length - 1;
}
