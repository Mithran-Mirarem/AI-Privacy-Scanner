import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/detection.dart';

class ReflectionResult {
  final bool suspicious;
  final int brightRegions;
  const ReflectionResult({required this.suspicious, required this.brightRegions});
}

class ReflectionDetector {
  ReflectionResult analyze(Uint8List bytes, List<Detection> detections) {
    final source = img.decodeImage(bytes);
    if (source == null) return const ReflectionResult(suspicious: false, brightRegions: 0);
    final suspicious = detections.where((d) => {'hidden_camera','spy_camera','spy_lens'}.contains(d.label)).toList();
    if (suspicious.isEmpty) return const ReflectionResult(suspicious: false, brightRegions: 0);
    final small = img.copyResize(source, width: 320);
    final maxArea = math.max(2, (small.width * small.height * .004).round());
    final visited = List<bool>.filled(small.width * small.height, false);
    var regions = 0;
    bool bright(int x, int y) {
      final p = small.getPixel(x, y);
      final lum = 0.2126*p.r + 0.7152*p.g + 0.0722*p.b;
      return lum > 245;
    }
    for (var y=1; y<small.height-1; y++) for (var x=1; x<small.width-1; x++) {
      final idx=y*small.width+x;
      if (visited[idx] || !bright(x,y)) continue;
      final q=<int>[idx]; visited[idx]=true; var head=0, area=0, hit=false;
      while(head<q.length){
        final cur=q[head++], cx=cur%small.width, cy=cur~/small.width; area++;
        final sx=cx/small.width, sy=cy/small.height;
        if (suspicious.any((d)=>d.left<=sx && sx<=d.right && d.top<=sy && sy<=d.bottom)) hit=true;
        const ns=[[-1,0],[1,0],[0,-1],[0,1]];
        for(final n in ns){final nx=cx+n[0], ny=cy+n[1]; if(nx<0||nx>=small.width||ny<0||ny>=small.height) continue; final ni=ny*small.width+nx; if(!visited[ni]&&bright(nx,ny)){visited[ni]=true;q.add(ni);}}
      }
      if(hit && area>=2 && area<=maxArea) regions++;
    }
    return ReflectionResult(suspicious: regions>0, brightRegions: regions);
  }
}
