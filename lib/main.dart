import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logger/logger.dart';


enum SendMessageStatus{
  sending,
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
      home: GameArea(),
    );
  }
}

/// The game area with all the components.
class GameArea extends HookWidget {
  const GameArea({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var powerMeterAnimCtrl = useAnimationController(duration: const Duration(milliseconds: 500));
    var stopPosition = useState(0.0);
    useEffect((){
      powerMeterAnimCtrl..forward()..repeat(reverse: true);
      return (){};
    }, [powerMeterAnimCtrl]);
    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTap: (){
            powerMeterAnimCtrl.stop();
            stopPosition.value = powerMeterAnimCtrl.value;

          },
          onLongPress: (){
            if(!powerMeterAnimCtrl.isAnimating){
              powerMeterAnimCtrl..forward()..repeat(reverse: true);
            }
          },
          child: Stack(
            children:  [
              const BackgroundImage(),
              const LoveLetter(count: 1),

              const Align(
                alignment: Alignment.topRight,
                child: LoveLetter(count: 3),
              ),

              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: AnimatedPowerMeter(width: MediaQuery.of(context).size.width / 2, animation: powerMeterAnimCtrl),
                ),
              ),
              const Positioned(
                bottom: 100,
                left: -100,
                child: Castle1(),
              ),
              const Positioned(
                bottom: 100,
                right: -100,
                child: Castle2(),
              ),
              const Center(
                child: Pigeon(
                  flightDirection: FlightDirection.left,
                ),
              ),
              Align(
                alignment: FractionalOffset(0.5, 0.7),
                child: Text(stopPosition.value.toString(), style: TextStyle(fontSize: 30, color: Colors.black, fontWeight: FontWeight.bold),),
              ),
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
  const Castle1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all()
      ),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
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
  const Castle2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 3,
      child: Image.asset(
        'assets/castle2.png',
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
  const Pigeon({
    Key? key,
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
        height: 50,
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
