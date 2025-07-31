for x in {1..50}; do
    dart run ./simulator.dart $x noFearNoChat
    # dart run ./simulator.dart $x fearNoChat
    # dart run ./simulator.dart $x noFearChat
    # dart run ./simulator.dart $x fearChat
done

