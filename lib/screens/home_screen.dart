import 'package:flutter/material.dart';
import 'scan_screen.dart';
import 'wifi_screen.dart';
import 'magnetometer_screen.dart';
import 'diagnostics_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('AI Privacy Scanner')),body:ListView(padding:const EdgeInsets.all(18),children:[
    _card(context,'AI Camera Scan','YOLOv8n + small-object tiled inference',Icons.camera_alt,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ScanScreen())),true),
    _card(context,'Wi-Fi Scanner','Visible nearby access points',Icons.wifi,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const WifiScreen())),false),
    _card(context,'Magnetometer','Magnetic-field magnitude stream',Icons.explore,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MagnetometerScreen())),false),
    _card(context,'Diagnostics','Model, camera and sensor readiness',Icons.health_and_safety,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const DiagnosticsScreen())),false),
    _card(context,'Scan History','Saved scan evidence from this session',Icons.history,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const HistoryScreen())),false),
    const SizedBox(height:12),
    const Text('Review 2 prototype',style:TextStyle(color:Colors.white54)),
    const SizedBox(height:6),
    const Text('Visual AI is the primary detection signal. Optical, Wi-Fi and magnetometer modules are supporting/next-stage components.',style:TextStyle(color:Colors.white70)),
  ]));
  static Widget _card(BuildContext c,String title,String sub,IconData icon,VoidCallback go,bool primary)=>Card(child:ListTile(leading:Icon(icon,color:primary?Colors.cyanAccent:Colors.white70,size:30),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(sub),trailing:const Icon(Icons.chevron_right),onTap:go));
}
