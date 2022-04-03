import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:love_letters/main.dart';

class WinnerScreen extends HookWidget{
  final int winnerNo;
  const WinnerScreen({Key? key, required this.winnerNo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Theme(
      data: Theme.of(context).copyWith(textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.white)),
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("The winner".toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 2),),
              const SizedBox(height: 30,),
              Text("Player $winnerNo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),),
              const SizedBox(height: 40,),
              MaterialButton(onPressed: (){
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameArea()));
              }, child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.replay, size: 28,),
                    SizedBox(width: 16,),
                    Text("Replay", style: TextStyle(fontSize: 20, letterSpacing: 1),)
                  ],
                ),
                color: Colors.yellow,
                height: 54,
                minWidth: 200,

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              )

            ],
          ),
        ),
      ),
    );
  }

}