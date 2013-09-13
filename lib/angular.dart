library angular;

import 'package:di/di.dart';
import 'package:di/dynamic_injector.dart';
import 'package:perf_api/perf_api.dart';

// TODO(misko): to be deleted
import 'dom/debug.dart';
import 'relax_fn_apply.dart';
import 'exception_handler.dart';
import "dart:mirrors";
import "dart:async" as async;
import "dart:json" as json;
import 'dart:html' as dom;

import 'zone.dart';                   export 'zone.dart';
import 'cache.dart';                  export 'cache.dart';
import 'interpolate.dart';            export 'interpolate.dart';
import 'dom/http.dart';               export 'dom/http.dart';
import 'parser/parser_library.dart';  export 'parser/parser_library.dart';
import 'scope.dart';                  export 'scope.dart';


part 'directives/ng_bind.dart';
part 'directives/ng_class.dart';
part 'directives/ng_click.dart';
part 'directives/ng_cloak.dart';
part 'directives/ng_controller.dart';
part 'directives/ng_disabled.dart';
part 'directives/ng_hide.dart';
part 'directives/ng_if.dart';
part 'directives/ng_include.dart';
part 'directives/ng_model.dart';
part 'directives/ng_mustache.dart';
part 'directives/ng_repeat.dart';
part 'directives/ng_show.dart';
part 'dom/block.dart';
part 'dom/compiler.dart';
part 'directive.dart';
part 'dom/dom_utilities.dart';
part 'dom/node_cursor.dart';
part 'dom/selector.dart';

toJson(obj) {
  try {
    return json.stringify(obj);
  } catch(e) {
    return "NOT-JSONABLE (see toJson(obj) in angular.dart)";
  }
}

class AngularModule extends Module {
  DirectiveRegistry _directives = new DirectiveRegistry();
  ControllerRegistry _controllers = new ControllerRegistry();

  AngularModule() {
    value(DirectiveRegistry, _directives);
    value(ControllerRegistry, _controllers);
    type(Compiler);
    type(ExceptionHandler);
    type(Scope);
    type(Parser, implementedBy: DynamicParser);
    type(DynamicParser);
    type(Lexer);
    type(ParserBackend);
    type(Interpolate);
    type(Http);
    type(UrlRewriter);
    type(HttpBackend);
    type(BlockCache);
    type(TemplateCache);
    type(GetterSetter);
    type(Profiler, implementedBy: _NoOpProfiler);
    type(ScopeDigestTTL);
    type(dom.NodeTreeSanitizer, implementedBy: NullTreeSanitizer);


    directive(NgTextMustacheDirective);
    directive(NgAttrMustacheDirective);

    directive(NgBindAttrDirective);
    directive(NgClassAttrDirective);
    directive(NgClickAttrDirective);
    directive(NgCloakAttrDirective);
    directive(NgControllerAttrDirective);
    directive(NgDisabledAttrDirective);
    directive(NgHideAttrDirective);
    directive(NgIfAttrDirective);
    directive(NgIncludeAttrDirective);
    directive(NgRepeatAttrDirective);
    directive(NgShowAttrDirective);

    directive(InputTextDirective);
    directive(InputCheckboxDirective);
    directive(NgModel);
  }

  directive(Type directive) {
    _directives.register(directive);
    return this;
  }

  controller(String name, Type controllerType) {
    _controllers.register(name, controllerType);
    type(controllerType);
  }
}


class ControllerRegistry {
  Map<String, Type> controllerMap = {};

  register(String name, Type controllerType) {
    controllerMap[name] = controllerType;
  }

  Type operator[](String name) {
    if (controllerMap.containsKey(name)){
      return controllerMap[name];
    } else {
      throw new ArgumentError('Unknown controller: $name');
    }
  }
}


// helper for bootstrapping angular
bootstrapAngular(modules, [rootElementSelector = '[ng-app]']) {
  var allModules = new List.from(modules);
  List<dom.Node> topElt = dom.query(rootElementSelector).nodes.toList();
  assert(topElt.length > 0);

  // The injector must be created inside the zone, so we create the
  // zone manually and give it back to the injector as a value.
  Zone zone = new Zone();
  allModules.add(new Module()..value(Zone, zone));

  zone.run(() {
    Injector injector = new DynamicInjector(modules: allModules);
    injector.get(Compiler)(topElt)(injector, topElt);
  });
}

bool understands(obj, symbol) {
  if (symbol is String) symbol = new Symbol(symbol);
  return reflect(obj).type.methods.containsKey(symbol);
}

class _NoOpProfiler extends Profiler {
  void markTime(String name, [String extraData]) { }

  int startTimer(String name, [String extraData]) => null;

  void stopTimer(idOrName) { }
}

class NullTreeSanitizer implements dom.NodeTreeSanitizer {
  void sanitizeTree(dom.Node node) {}
}
