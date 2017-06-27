(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['editor_block_template'] = template({"1":function(container,depth0,helpers,partials,data) {
    var helper, alias1=container.escapeExpression;

  return "                <option value=\""
    + alias1(((helper = (helper = helpers.index || (data && data.index)) != null ? helper : helpers.helperMissing),(typeof helper === "function" ? helper.call(depth0 != null ? depth0 : {},{"name":"index","hash":{},"data":data}) : helper)))
    + "\">"
    + alias1(container.lambda((depth0 != null ? depth0.Sigla : depth0), depth0))
    + "</option>\n";
},"compiler":[7,">= 4.0.0"],"main":function(container,depth0,helpers,partials,data) {
    var stack1, helper, alias1=depth0 != null ? depth0 : {}, alias2=helpers.helperMissing, alias3="function", alias4=container.escapeExpression, alias5=container.lambda;

  return "<div class=\"row\" id=\"blockrow\">\n    <div class=\"col-md-1\">\n        <select id=\"cmd-select\" name=\"cmd_select_"
    + alias4(((helper = (helper = helpers.idx || (depth0 != null ? depth0.idx : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"idx","hash":{},"data":data}) : helper)))
    + "\" tabindex=\""
    + alias4(((helper = (helper = helpers.idx || (depth0 != null ? depth0.idx : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"idx","hash":{},"data":data}) : helper)))
    + "\" class=\"form-control\">\n            <!--onchange=\"refresh(this)\"-->\n"
    + ((stack1 = helpers.each.call(alias1,(depth0 != null ? depth0.blocks : depth0),{"name":"each","hash":{},"fn":container.program(1, data, 0),"inverse":container.noop,"data":data})) != null ? stack1 : "")
    + "        </select>\n    </div>\n    <div class=\"col-md-2\">\n        <div class=\"row\">\n\n            <div class=\"col-md-6\"><input placeholder=\"Node\" name=\"cmd_node-1_"
    + alias4(((helper = (helper = helpers.idx || (depth0 != null ? depth0.idx : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"idx","hash":{},"data":data}) : helper)))
    + "\" class=\"form-control\"/></div>\n            <div class=\"col-md-6\"><input placeholder=\"Node\" name=\"cmd_node-2_"
    + alias4(((helper = (helper = helpers.idx || (depth0 != null ? depth0.idx : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"idx","hash":{},"data":data}) : helper)))
    + "\" class=\"form-control\"/></div>\n        </div>\n    </div>\n    <div class=\"col-md-1\">\n        <input id=\"input-E\" name=\"cmd_input-E_"
    + alias4(((helper = (helper = helpers.idx || (depth0 != null ? depth0.idx : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"idx","hash":{},"data":data}) : helper)))
    + "\" class=\"form-control\" placeholder=\""
    + alias4(alias5(((stack1 = ((stack1 = (depth0 != null ? depth0.blocks : depth0)) != null ? stack1["0"] : stack1)) != null ? stack1.E_name : stack1), depth0))
    + "\"/>\n    </div>\n    <div class=\"col-md-1\">\n        <input id=\"input-F\" name=\"cmd_input-F_"
    + alias4(((helper = (helper = helpers.idx || (depth0 != null ? depth0.idx : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"idx","hash":{},"data":data}) : helper)))
    + "\" class=\"form-control\" placeholder=\""
    + alias4(alias5(((stack1 = ((stack1 = (depth0 != null ? depth0.blocks : depth0)) != null ? stack1["0"] : stack1)) != null ? stack1.F_name : stack1), depth0))
    + "\"/>\n    </div>\n    <div class=\"col-md-1\">\n        <input id=\"input-Q\" name=\"cmd_input-Q_"
    + alias4(((helper = (helper = helpers.idx || (depth0 != null ? depth0.idx : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"idx","hash":{},"data":data}) : helper)))
    + "\" class=\"form-control\" placeholder=\""
    + alias4(alias5(((stack1 = ((stack1 = (depth0 != null ? depth0.blocks : depth0)) != null ? stack1["0"] : stack1)) != null ? stack1.Q_name : stack1), depth0))
    + "\"/>\n    </div>\n    <div class=\"col-md-1\">\n        <input id=\"input-K\" name=\"cmd_input-K_"
    + alias4(((helper = (helper = helpers.idx || (depth0 != null ? depth0.idx : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"idx","hash":{},"data":data}) : helper)))
    + "\" class=\"form-control\" placeholder=\""
    + alias4(alias5(((stack1 = ((stack1 = (depth0 != null ? depth0.blocks : depth0)) != null ? stack1["0"] : stack1)) != null ? stack1.K_name : stack1), depth0))
    + "\"/>\n    </div>\n    <div class=\"col-md-1\">\n        <div class=\"row\">\n            <a id=\"delete\" href=\"#\" class=\"btn btn-danger\"><i class=\"fa fa-minus\"></i></a>\n            <a id=\"add-branch-button\" href=\"#\" class=\"btn btn-success\" tabindex=\""
    + alias4(((helper = (helper = helpers.idx || (depth0 != null ? depth0.idx : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"idx","hash":{},"data":data}) : helper)))
    + "\"><i class=\"fa fa-plus\"></i></a>\n        </div>\n    </div>\n    <div class=\"col-md-1\">\n         <span id=\"help-label\" class=\"label label-default\">\n             "
    + alias4(alias5(((stack1 = ((stack1 = (depth0 != null ? depth0.blocks : depth0)) != null ? stack1["0"] : stack1)) != null ? stack1.Help_ENG : stack1), depth0))
    + "\n         </span>\n    </div>\n</div>\n<p></p>";
},"useData":true});
})();