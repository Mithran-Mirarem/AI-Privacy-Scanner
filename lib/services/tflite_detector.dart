import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection.dart';

class TfliteDetector {
  static const labels = ['camera','cctv','hidden_camera','spy_camera','spy_lens'];
  static const inputSize = 640;
  static const acceptance = {'camera':0.30,'cctv':0.30,'hidden_camera':0.70,'spy_camera':0.50,'spy_lens':0.50};
  static const iouThreshold = 0.45;
  Interpreter? _interpreter;
  List<int> _shape = const [];
  bool _inputIsNchw = false;
  bool get isReady => _interpreter != null;

  Future<void> load() async {
    final i = await Interpreter.fromAsset('assets/models/privacy_scanner.tflite',
      options: InterpreterOptions()..threads = 2);
    // Allocate tensors before the first invocation to avoid an unallocated-tensor precondition error.
    i.allocateTensors();
    final input = i.getInputTensor(0);
    final inputShape = input.shape;
    final isNhwc = inputShape.length == 4 &&
        inputShape[0] == 1 &&
        inputShape[1] == inputSize &&
        inputShape[2] == inputSize &&
        inputShape[3] == 3;
    final isNchw = inputShape.length == 4 &&
        inputShape[0] == 1 &&
        inputShape[1] == 3 &&
        inputShape[2] == inputSize &&
        inputShape[3] == inputSize;
    if (input.type != TensorType.float32 || (!isNhwc && !isNchw)) {
      i.close();
      throw StateError(
        'Unsupported model input tensor: shape=$inputShape type=${input.type}; expected float32 [1, 640, 640, 3] (NHWC) or [1, 3, 640, 640] (NCHW).',
      );
    }
    _inputIsNchw = isNchw;
    _interpreter = i;
    _shape = i.getOutputTensor(0).shape;
    if (_shape.length != 3 || _shape[0] != 1) {
      i.close();
      _interpreter = null;
      throw StateError('Unsupported YOLO output tensor shape: $_shape. Expected [1, channels, candidates] or [1, candidates, channels].');
    }
  }
  void close(){_interpreter?.close();_interpreter=null;}

  img.Image _source(img.Image s)=>img.bakeOrientation(s);
  ({img.Image image,double scale,double dx,double dy,int sw,int sh}) _letterbox(img.Image s){
    final scale=math.min(inputSize/s.width,inputSize/s.height); final rw=math.max(1,(s.width*scale).round()); final rh=math.max(1,(s.height*scale).round());
    final r=img.copyResize(s,width:rw,height:rh,interpolation:img.Interpolation.linear); final c=img.Image(width:inputSize,height:inputSize); img.fill(c,color:img.ColorRgb8(114,114,114));
    final dx=(inputSize-rw)/2,dy=(inputSize-rh)/2; img.compositeImage(c,r,dstX:dx.round(),dstY:dy.round()); return (image:c,scale:scale,dx:dx,dy:dy,sw:s.width,sh:s.height);
  }

  dynamic _input(img.Image im) {
    if (_inputIsNchw) {
      // NCHW: [batch, channel, height, width]. Keep RGB channel order.
      return [
        List.generate(
          3,
          (channel) => List.generate(
            inputSize,
            (y) => List.generate(inputSize, (x) {
              final pixel = im.getPixel(x, y);
              final value = channel == 0
                  ? pixel.r
                  : channel == 1
                      ? pixel.g
                      : pixel.b;
              return value / 255.0;
            }),
          ),
        ),
      ];
    }

    // NHWC: [batch, height, width, channel].
    return [
      List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = im.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    ];
  }

  dynamic _buffer(){
    if(_shape.length==3) return List.generate(_shape[0],(_)=>List.generate(_shape[1],(_)=>List<double>.filled(_shape[2],0)));
    if(_shape.length==2) return List.generate(_shape[0],(_)=>List<double>.filled(_shape[1],0));
    throw StateError('Unsupported output shape $_shape');
  }
  List<double> _vector(dynamic out,int i){
    if(_shape.length==3 && _shape[1]<_shape[2]) return List.generate(_shape[1],(c)=>(out[0][c][i] as num).toDouble());
    final channels=_shape.last; return List.generate(channels,(c)=>(out[0][i][c] as num).toDouble());
  }
  double _iou(Detection a,Detection b){final l=math.max(a.left,b.left),t=math.max(a.top,b.top),r=math.min(a.right,b.right),bo=math.min(a.bottom,b.bottom);final inter=math.max(0,r-l)*math.max(0,bo-t);final aa=(a.right-a.left)*(a.bottom-a.top),ab=(b.right-b.left)*(b.bottom-b.top);return inter/math.max(1e-9,aa+ab-inter);}
  List<Detection> _nms(List<Detection> ds){final out=<Detection>[];for(var cid=0;cid<labels.length;cid++){final g=ds.where((d)=>d.classId==cid).toList()..sort((a,b)=>b.confidence.compareTo(a.confidence));while(g.isNotEmpty){final best=g.removeAt(0);out.add(best);g.removeWhere((d)=>_iou(best,d)>=iouThreshold);}}out.sort((a,b)=>b.confidence.compareTo(a.confidence));return out;}

  List<Detection> _decode(dynamic out,{required double scale,required double dx,required double dy,required int sw,required int sh,required double candidate} ){
    final n=_shape.length==3?(_shape[1]<_shape[2]?_shape[2]:_shape[1]):_shape[0]; final result=<Detection>[];
    for(var i=0;i<n;i++){final v=_vector(out,i);if(v.length<5)continue;final cx=v[0],cy=v[1],bw=v[2],bh=v[3];var bid=-1,bs=0.0;for(var c=4;c<v.length&&c-4<labels.length;c++){if(v[c]>bs){bs=v[c];bid=c-4;}}if(bid<0||bs<candidate)continue;final left=((cx-bw/2-dx)/scale/sw).clamp(0.0,1.0),top=((cy-bh/2-dy)/scale/sh).clamp(0.0,1.0),right=((cx+bw/2-dx)/scale/sw).clamp(0.0,1.0),bottom=((cy+bh/2-dy)/scale/sh).clamp(0.0,1.0);if(right<=left||bottom<=top)continue;final label=labels[bid];if(bs<(acceptance[label]??candidate))continue;result.add(Detection(classId:bid,label:label,confidence:bs,left:left,top:top,right:right,bottom:bottom));}
    return _nms(result);
  }
  Future<List<Detection>> _run(img.Image src,double candidate) async {final i=_interpreter;if(i==null)throw StateError('TFLite model is not loaded.');final t=_letterbox(src);final out=_buffer();try { i.run(_input(t.image),out); } catch (e) { throw StateError('TFLite inference failed. Input=${i.getInputTensor(0).shape}/${i.getInputTensor(0).type}, output=${i.getOutputTensor(0).shape}/${i.getOutputTensor(0).type}. $e'); } return _decode(out,scale:t.scale,dx:t.dx,dy:t.dy,sw:t.sw,sh:t.sh,candidate:candidate);}
  Future<List<Detection>> detectBytes(Uint8List bytes,{double candidate=0.18}) async {final s=img.decodeImage(bytes);if(s==null)throw StateError('Could not decode image');return _run(_source(s),candidate);}
  Future<List<Detection>> detectBytesTiled(Uint8List bytes,{double candidate=0.18}) async {final s=img.decodeImage(bytes);if(s==null)throw StateError('Could not decode image');final src=_source(s);final all=<Detection>[];all.addAll(await _run(src,candidate));final fw=src.width,fh=src.height;final rs=<List<int>>[[0,0,(fw*.6).round(),(fh*.6).round()],[ (fw*.4).round(),0,fw,(fh*.6).round()],[0,(fh*.4).round(),(fw*.6).round(),fh],[(fw*.4).round(),(fh*.4).round(),fw,fh]];for(final q in rs){final x1=q[0],y1=q[1],x2=q[2],y2=q[3];final crop=img.copyCrop(src,x:x1,y:y1,width:x2-x1,height:y2-y1);for(final d in await _run(crop,candidate)){all.add(Detection(classId:d.classId,label:d.label,confidence:d.confidence,left:(x1+d.left*(x2-x1))/fw,top:(y1+d.top*(y2-y1))/fh,right:(x1+d.right*(x2-x1))/fw,bottom:(y1+d.bottom*(y2-y1))/fh));}}return _nms(all);}
}
