for x in {1..50}; do
    dart run ./simulator_homogeneous.dart $x noFearNoChat
    dart run ./simulator_homogeneous.dart $x fearNoChat
    dart run ./simulator_homogeneous.dart $x noFearChat
    dart run ./simulator_homogeneous.dart $x fearChat
done

