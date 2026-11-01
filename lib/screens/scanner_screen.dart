import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget { const ScannerScreen({super.key}); @override State<ScannerScreen> createState()=>_ScannerScreenState(); }
class _ScannerScreenState extends State<ScannerScreen>{
  bool found=false;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Scanner un code-barres')),body:Stack(children:[
    MobileScanner(onDetect:(capture){if(found)return;final code=capture.barcodes.firstOrNull?.rawValue;if(code!=null&&code.trim().isNotEmpty){found=true;Navigator.pop(context,code.trim());}}),
    Center(child:Container(width:280,height:150,decoration:BoxDecoration(border:Border.all(color:Colors.greenAccent,width:3),borderRadius:BorderRadius.circular(12)))),
    const Positioned(left:20,right:20,bottom:30,child:Card(child:Padding(padding:EdgeInsets.all(12),child:Text('Placez le code-barres dans le cadre. La détection est automatique.',textAlign:TextAlign.center)))),
  ]));
}
