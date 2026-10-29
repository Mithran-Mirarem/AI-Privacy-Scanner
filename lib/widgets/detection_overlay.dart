import 'package:flutter/material.dart';
import '../models/detection.dart';

class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;
  const DetectionOverlay({super.key,required this.detections});
  @override Widget build(BuildContext context)=>IgnorePointer(child:CustomPaint(size:Size.infinite,painter:_Painter(detections)));
}
class _Painter extends CustomPainter {
  final List<Detection> detections; _Painter(this.detections);
  @override void paint(Canvas canvas,Size size){final p=Paint()..style=PaintingStyle.stroke..strokeWidth=3;for(final d in detections){final bad={'hidden_camera','spy_camera','spy_lens'}.contains(d.label);p.color=bad?Colors.redAccent:Colors.cyanAccent;final r=Rect.fromLTRB(d.left*size.width,d.top*size.height,d.right*size.width,d.bottom*size.height);canvas.drawRect(r,p);final tp=TextPainter(text:TextSpan(text:'${d.label} ${(d.confidence*100).round()}%',style:const TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w700)),textDirection:TextDirection.ltr)..layout();final bg=Paint()..color=bad?Colors.redAccent:Colors.cyan[800]!;final top=(r.top-tp.height-4).clamp(0.0,size.height-tp.height-4);canvas.drawRect(Rect.fromLTWH(r.left,top,tp.width+8,tp.height+4),bg);tp.paint(canvas,Offset(r.left+4,top+2));}}
  @override bool shouldRepaint(covariant _Painter oldDelegate)=>oldDelegate.detections!=detections;
}
