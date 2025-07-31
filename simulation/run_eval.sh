for x in {1..50}; do
    # dart run ./evaluator.dart $x hCAB
    dart run ./evaluator.dart $x eCAB
    # dart run ./evaluator.dart $x mixed_noFear_noChat
    # dart run ./evaluator.dart $x mixed_fear_noChat
    # dart run ./evaluator.dart $x mixed_noFear_chat
    # dart run ./evaluator.dart $x mixed_fear_chat
    # dart run ./evaluator.dart $x homogeneous_noFear_noChat
    # dart run ./evaluator.dart $x homogeneous_fear_noChat
    # dart run ./evaluator.dart $x homogeneous_noFear_chat
    # dart run ./evaluator.dart $x homogeneous_fear_chat
    # dart run ./evaluator.dart $x noFear_noChat
    # dart run ./evaluator.dart $x fear_noChat
    # dart run ./evaluator.dart $x noFear_chat
    # dart run ./evaluator.dart $x fear_chat
done
