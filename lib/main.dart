import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logger/logger.dart';
import 'package:love_letters/winner_screen.dart';


enum SendingLetterStatus{
  waiting,
  failed,
  sent
}

void main() {
  runApp(const CannonCastleApp());

}

/// The main application.
class CannonCastleApp extends StatelessWidget {
  const CannonCastleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameArea(),
    );
  }
}

/// The game area with all the components.
class GameArea extends HookWidget {
  final powerMeterLowerBound = 90;
  final powerMeterUpperBound = 110;
  final maxPointsToFinish = 5;
  const GameArea({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Not rebuild the view
    var sendingLetterStatus = useRef(SendingLetterStatus.waiting);

    var powerMeterAnimCtrl = useAnimationController(duration: const Duration(milliseconds: 5000));
    var powerMeterIsStopped = useState(false);
    var powerMeterWidth = useMemoized(() => MediaQuery.of(context).size.width / 2);
    // Flight movement controller
    var flightMovAnimCtrl = useAnimationController(duration: const Duration(milliseconds: 1000));
    var castleWidth = useMemoized(() => MediaQuery.of(context).size.width / 3);
    var castleXOffset = useMemoized(() => 100.0);
    var pigeonHeight = useMemoized(() => 50.0);
    var flightDistance = useMemoized(() => MediaQuery.of(context).size.width - (castleWidth * 2) + castleXOffset * 2);
    var flightDirection = useState<FlightDirection>(FlightDirection.right);

    // Success interval bounds (lower and upper bounds)
    // Todo: Make bounds configurables (feat)

    var lowerBound = useMemoized(() => (powerMeterLowerBound * 0.5) / 100);
    var upperBound = useMemoized(() => (powerMeterUpperBound * 0.5) / 100);

    // Letter future status
    // Player points
    var firstPlayerPoints = useState(0);
    var secondPlayerPoints = useState(0);
    var maxPoints = useMemoized(() => math.max(firstPlayerPoints.value, secondPlayerPoints.value), [
      firstPlayerPoints.value,
      secondPlayerPoints.value
    ]);
    Animation<double> pigeonXAnimation = useMemoized((){
      if(powerMeterIsStopped.value){
        var startDistance = castleWidth - castleXOffset - pigeonHeight;
        var endDistance = startDistance + flightDistance + pigeonHeight;
        if(lowerBound <= powerMeterAnimCtrl.value && powerMeterAnimCtrl.value <= upperBound){
          // Letter will be send successfully in this case
          sendingLetterStatus.value = SendingLetterStatus.sent;
          if(flightDirection.value == FlightDirection.right) {
            return Tween<double>(begin: startDistance, end: endDistance).animate(flightMovAnimCtrl);
          }
          else {
            return Tween<double>(begin: endDistance - pigeonHeight, end: startDistance).animate(flightMovAnimCtrl);
          }
        }
        else{
          // Letter won't be send  in this case
          sendingLetterStatus.value = SendingLetterStatus.failed;
          if(flightDirection.value == FlightDirection.right) {
            endDistance = (powerMeterAnimCtrl.value < lowerBound)
                ? startDistance + (powerMeterAnimCtrl.value * flightDistance / lowerBound)
                : startDistance + ((1 - powerMeterAnimCtrl.value) * flightDistance / lowerBound);
            return Tween<double>(begin: startDistance, end: endDistance).animate(
                CurvedAnimation(parent: flightMovAnimCtrl, curve: const Interval(0.0, 0.75))
            );
          }
          else {
            startDistance = flightDistance + castleWidth - castleXOffset;
            endDistance = flightDistance - ((powerMeterAnimCtrl.value > upperBound)
                ? ((1 - powerMeterAnimCtrl.value) * flightDistance / lowerBound)
                : ((powerMeterAnimCtrl.value) * flightDistance / lowerBound));

            return Tween<double>(begin: startDistance, end: endDistance).animate(
                CurvedAnimation(parent: flightMovAnimCtrl, curve: const Interval(0.0, 0.75)));
          }
        }
      }
      double defaultX = flightDirection.value == FlightDirection.right
      ? castleWidth - castleXOffset - pigeonHeight
      : flightDistance + (castleWidth - castleXOffset);

      return Tween<double>(begin: defaultX ,end: defaultX ).animate(flightMovAnimCtrl);
      //return flightMovAnimCtrl;
    }, [powerMeterIsStopped.value]);

    Animation<double> pigeonYAnimation = useMemoized((){
      if(powerMeterIsStopped.value){
        var begin = (MediaQuery.of(context).size.height / 2) - pigeonHeight / 2;
        var end = MediaQuery.of(context).size.height;
        if(lowerBound <= powerMeterAnimCtrl.value && powerMeterAnimCtrl.value <= upperBound){
          return Tween(begin: begin, end: begin).animate(flightMovAnimCtrl);
        }
        //Logger().d("Outside bounds");
        return Tween(begin: begin, end: end).animate(CurvedAnimation(parent: flightMovAnimCtrl, curve: const Interval(0.75, 1)));
      }

      var defaultY = (MediaQuery.of(context).size.height / 2) - pigeonHeight / 2;
      return Tween<double>(begin: defaultY, end: defaultY).animate(flightMovAnimCtrl);
      //return flightMovAnimCtrl;
    }, [powerMeterIsStopped.value]);


    useEffect((){
     if(powerMeterIsStopped.value){
       powerMeterAnimCtrl.stop();
       flightMovAnimCtrl.forward();
     }else{
       flightMovAnimCtrl.reset();
       sendingLetterStatus.value = SendingLetterStatus.waiting;
       powerMeterAnimCtrl..forward()..repeat(reverse: true);
     }
     return null;
    }, [powerMeterIsStopped.value]);

    useEffect((){
      void _handleStatus (AnimationStatus status){
        if(status == AnimationStatus.completed){
          if(flightDirection.value == FlightDirection.right){
            if(sendingLetterStatus.value == SendingLetterStatus.sent) {
              firstPlayerPoints.value ++;
            }
            flightDirection.value = FlightDirection.left;
          }
          else{
            if(sendingLetterStatus.value == SendingLetterStatus.sent) {
              secondPlayerPoints.value ++;
            }
            flightDirection.value = FlightDirection.right;
          }
          powerMeterIsStopped.value = false;
        }
      }
      flightMovAnimCtrl.addStatusListener(_handleStatus);
      return () => flightMovAnimCtrl.removeStatusListener(_handleStatus);
    }, [flightMovAnimCtrl]);

    useEffect((){
      if(maxPoints == maxPointsToFinish){
        int winner = firstPlayerPoints.value > secondPlayerPoints.value ? 1 : 2;
        // Send to micro tasks loop
        Future.delayed(Duration.zero, () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) =>  WinnerScreen(winnerNo: winner,))));
      }
      return null;
    }, [maxPoints]);
    // Check if app rebuilds uselessly (you can uncomment and see it in console)
    // Logger().d("Rebuild");


    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTap: (){
            powerMeterIsStopped.value = true;
          },

          child: Stack(
            children:  [
              const BackgroundImage(),
              Positioned(left: 14, child: LoveLetter(count: firstPlayerPoints.value)),

              Positioned(
                right: 14,
                child: Align(
                  alignment: Alignment.topRight,
                  child: LoveLetter(count: secondPlayerPoints.value),
                ),
              ),

              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: AnimatedPowerMeter(width: powerMeterWidth, animation: powerMeterAnimCtrl),
                ),
              ),
              Positioned(
                bottom: 100,
                left: - castleXOffset,
                child: Castle1(castleWidth: castleWidth),
              ),
              Positioned(
                bottom: 100,
                right: - castleXOffset,
                child: Castle2(castleWidth: castleWidth),
              ),
              AnimatedBuilder(
                animation: flightMovAnimCtrl,
                child: Center(
                  child: Pigeon(
                    pigeonHeight: pigeonHeight,
                    flightDirection: flightDirection.value,
                  ),
                ),
                builder: (_, child){
                  return Positioned(
                    left: pigeonXAnimation.value,
                    top: pigeonYAnimation.value,
                    child: child!
                  );
                },
              ),
             /* Align(
                alignment: const FractionalOffset(0.5, 0.7),
                child: Text("Power Meter Stop: ${powerMeterIsStopped.value}", style: const TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}

/// The backround of the game.
class BackgroundImage extends StatelessWidget {
  const BackgroundImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        'assets/background.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

/// The castle on the left.
class Castle1 extends StatelessWidget {
  final double castleWidth;
  const Castle1({Key? key, required this.castleWidth}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        //border: Border.all()
      ),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: SizedBox(
          width: castleWidth,
          child: Image.asset(
            'assets/castle1.png',
          ),
        ),
      ),
    );
  }
}

/// The castle on the right.
class Castle2 extends StatelessWidget {
  final double castleWidth;
  const Castle2({Key? key, required this.castleWidth}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          //border: Border.all()
      ),
      child: SizedBox(
        width: castleWidth,
        child: Image.asset(
          'assets/castle2.png',
        ),
      ),
    );
  }
}

enum FlightDirection {
  left,
  right,
}

/// The cannon ball that we will shoot.
class Pigeon extends StatelessWidget {
  final double pigeonHeight;
  const Pigeon({
    Key? key,
    required this.pigeonHeight,
    required this.flightDirection,
  }) : super(key: key);

  final FlightDirection flightDirection;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: flightDirection == FlightDirection.left
          ? Matrix4.identity()
          : Matrix4.rotationY(math.pi),
      child: SizedBox(
        height: pigeonHeight,
        child: Image.asset('assets/carrier_pigeon.png'),
      ),
    );
  }
}

/// The meter that displays a moving bar which determines the power of the
/// shoot.
class PowerMeter extends StatelessWidget {
  final Animation<double> animation;
  final double width;
  const PowerMeter({Key? key, required this.animation, required this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30.0,
      width: width,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(
                Radius.circular(2.0),
              ),
              border: Border.all(
                color: Colors.red,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 5.0,
                  spreadRadius: 0.0,
                ),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 0.0, vertical: 1.0),
              child: Container(
                color: Colors.grey,
                width: 10,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: animation,
            builder: (_, __) {
              return Align(
                alignment: FractionalOffset(animation.value, 0.5),
                child: const PowerMeterIndicator(),
              );
            }
          )
        ],
      ),
    );
  }
}
class AnimatedPowerMeter extends HookWidget{
  final AnimationController animation;
  final double width;
  const AnimatedPowerMeter({Key? key, required this.width,  required this.animation}): super(key: key);


  @override
  Widget build(BuildContext context) {

    return PowerMeter(animation: animation, width: width);
  }

}

/// The red line in the [PowerMeter] that goes left to right and right to left.
class PowerMeterIndicator extends StatelessWidget {
  const PowerMeterIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5.0,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.all(
          Radius.circular(2.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 5.0,
            spreadRadius: 0.0,
          ),
        ],
      ),
    );
  }
}

class LoveLetter extends StatelessWidget {
  const LoveLetter({
    Key? key,
    required this.count,
  }) : super(key: key);

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      width: 45,
      child: Stack(
        children: [
          Image.asset('assets/love_letter.png'),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.all(3.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 5.0,
                    spreadRadius: 0.0,
                  ),
                ],
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
