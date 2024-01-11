import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class WebContainer {
  int widthIndexToRender = 0;
  double renderWidthMin = 0;
  double renderWidthMax = 0;
  double appScreenMin = 0;
  double appScreenMax = 0;
  bool showAppFrame = false;
  bool renderingNarrow = false;
}

class Dimensions {
  bool landscapeView = false;
  double resolution = 1;
  double viewableWidth = 0;
  double viewableHeight = 0;
}

class Environment {
  String locale = "";
  bool runningOnLocalhost = false;
  bool runningOnWeb = false;
  String appOperatingSystem = "NA";
}

class SimpleWebContainer {
  static final SimpleWebContainer _singleton = SimpleWebContainer._internal();

  factory SimpleWebContainer() {
    return _singleton;
  }

  SimpleWebContainer._internal();

  bool initialized = false;

  WebContainer webContainer = WebContainer();
  Dimensions dimensions = Dimensions();
  Environment environment = Environment();

  List<double> _renderContainerWidths = [];
  double _containerMaxWidth = 0;

  void initialize({required List<double> renderContainerWidths, required BuildContext context}){
    final size = MediaQuery.sizeOf(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    _renderContainerWidths = renderContainerWidths;

    environment.locale = "US";
    environment.runningOnLocalhost = ( Uri.base.origin.toLowerCase().contains("localhost") ? true : false );
    environment.runningOnWeb = kIsWeb;

    if( !environment.runningOnWeb ){
      environment.appOperatingSystem = Platform.operatingSystem;
    }

    _renderContainerWidths.sort();

    _containerMaxWidth = _renderContainerWidths.last;

    dimensions.resolution = devicePixelRatio;
    dimensions.viewableWidth = size.width;
    dimensions.viewableHeight = size.height;

    _calculateContainerShape( viewableWidth: size.width, viewableHeight: size.height);

    initialized = true;
  }

  void _calculateContainerShape({required double viewableWidth, required double viewableHeight}){
    if( _renderContainerWidths.isEmpty ) return;

    if( _containerMaxWidth <= viewableWidth || _renderContainerWidths.last <= viewableWidth ){
      webContainer.widthIndexToRender = _renderContainerWidths.length-1;
    } else if( _renderContainerWidths.first >= viewableWidth ){
      webContainer.widthIndexToRender = 0;
    } else {
      for (var c = 0; c < _renderContainerWidths.length; c++ ) {
        double col = _renderContainerWidths[c];

        if( c < _renderContainerWidths.length-1 ){ // not the last index
          double nextCol = _renderContainerWidths[c+1];

          if( viewableWidth >= col && viewableWidth < nextCol){
            webContainer.widthIndexToRender = c;
            break;
          }

        } else { // the last index
          webContainer.widthIndexToRender = _renderContainerWidths.length-1;
        }
      }
    }

    webContainer.renderingNarrow = ( viewableWidth < _renderContainerWidths.first ? true : false );

    webContainer.renderWidthMax = viewableWidth;
    if( viewableWidth > _renderContainerWidths.last ) webContainer.renderWidthMax = _renderContainerWidths.last;

    webContainer.renderWidthMin = 500/dimensions.resolution;
    webContainer.renderWidthMin = ( webContainer.renderWidthMin >= webContainer.renderWidthMax ? ( webContainer.renderWidthMax - 100 ) : webContainer.renderWidthMin );
    webContainer.renderWidthMin = ( webContainer.renderWidthMin < 0 ? 0 : webContainer.renderWidthMin );

    webContainer.appScreenMin = 500/dimensions.resolution;
    webContainer.appScreenMax = _renderContainerWidths.last;
    webContainer.showAppFrame = ( viewableWidth < _containerMaxWidth ? false : true );

    dimensions.landscapeView = ( webContainer.renderWidthMax > viewableHeight ? true : false );
  }

  Widget _contentOutput(double containerHeightMin, double containerHeightMax, double containerWidthMin, double containerWidthMax, Widget mainContent, Color appBackgroundColor){
    return SizedBox(
        width: webContainer.appScreenMax,
        child: Container(
          color: appBackgroundColor,
          constraints: const BoxConstraints.expand(),
          child: Container(
              constraints: BoxConstraints(
                minHeight: containerHeightMin,
                maxHeight: containerHeightMax,
                minWidth: containerWidthMin,
                maxWidth: containerWidthMax,
              ),
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: mainContent
              )
          ),
        )
    );
  }

  Widget wrap({required Widget content, double minHeight = 1, double maxHeight = -1,
    Color appFrameColor = Colors.white, Color appBackgroundColor = Colors.white})
  {
    if( maxHeight == -1 ) maxHeight = dimensions.viewableHeight;

    if( webContainer.showAppFrame ){
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(color: appFrameColor, constraints: const BoxConstraints.expand()),
          ),
          _contentOutput(minHeight, maxHeight, webContainer.renderWidthMin, webContainer.renderWidthMax, content, appBackgroundColor),
          Expanded(
            child: Container(color: appFrameColor, constraints: const BoxConstraints.expand()),
          ),
        ],
      );
    } else {
      return _contentOutput(minHeight, maxHeight, webContainer.renderWidthMin, webContainer.renderWidthMax, content, appBackgroundColor);
    }
  }

  Widget showParameters(){
    List<Widget> parameterRows = [];
    double priorColumnWidth = 0;

    if(
    _renderContainerWidths[webContainer.widthIndexToRender] <= webContainer.renderWidthMax &&
        webContainer.renderWidthMax > webContainer.appScreenMin
    ){
      priorColumnWidth = _renderContainerWidths[webContainer.widthIndexToRender];

      if(
      priorColumnWidth == webContainer.renderWidthMax &&
          webContainer.widthIndexToRender > 0
      ) priorColumnWidth = _renderContainerWidths[webContainer.widthIndexToRender-1];

      parameterRows.add(
          Container(
            width: priorColumnWidth,
            height: 18,
            color: Colors.lightBlueAccent,
            child: Text("${priorColumnWidth}px Prior Container Space + ", style: const TextStyle(fontSize: 12)),
          )
      );
    }

    double containerRemainderWidth = webContainer.renderWidthMax - priorColumnWidth;

    parameterRows.add(
        Container(
          width: containerRemainderWidth,
          height: 18,
          color: Colors.yellow,
          child: Text("${containerRemainderWidth}px = Container Space", style: const TextStyle(fontSize: 12)),
        )
    );

    return Column(
      children: [
        Container(
          width: webContainer.renderWidthMax,
          height: 18,
          color: Colors.deepOrange,
          child: Text("App Size ${webContainer.widthIndexToRender+1} of ${_renderContainerWidths.length}, at ${webContainer.renderWidthMax}px", style: const TextStyle(fontSize: 12)),
        ),
        Row(
          children: parameterRows,
        )
      ],
    );
  }

  bool isWidestRender(){
    return ( webContainer.widthIndexToRender+1 == _renderContainerWidths.length ? true : false );
  }

  bool isThinnestRender(){
    return ( webContainer.widthIndexToRender == 0 ? true : false );
  }
}

var simpleWebContainer = SimpleWebContainer();