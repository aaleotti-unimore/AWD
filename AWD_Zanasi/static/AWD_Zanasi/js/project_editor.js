$(document).ready(function () {
    var csrftoken = jQuery("[name=csrfmiddlewaretoken]").val();
    $.ajax({
        beforeSend: function (xhr, settings) {
            if (!csrfSafeMethod(settings.type) && !this.crossDomain) {
                xhr.setRequestHeader("X-CSRFToken", csrftoken);
            }
        },
        url: '/pogmodeler/projects/create_project/editor/',
        type: 'POST',
        dataType: 'json',
        success: handle_response,
        error: function (xhr, err) {
            console.log("readyState: " + xhr.readyState + "\nstatus: " + xhr.status);
            console.log("responseText: " + xhr.responseText);
            return null;
        }
    });

    coordinates();

    function csrfSafeMethod(method) {
        // these HTTP methods do not require CSRF protection
        return (/^(GET|HEAD|OPTIONS|TRACE)$/.test(method));
    }

});

function handle_response(response) {
    var max_fields = 100;
    var blocks_wrapper = $("#blocks-form");
    var add_block_button = $(".add_block_btn");
    var blks = response["blocks"];
    var blocks_counter = 1;
    var context = {
        blocks: blks,
        idx: blocks_counter
    };
    var template = Handlebars.templates.editor_block_template(context);
    blocks_wrapper.append(template);

    $(add_block_button).click(function (e) {
        e.preventDefault();
        if (blocks_counter < max_fields) {
            blocks_counter++;
            var context2 = {
                blocks: blks,
                idx: blocks_counter
            };
            var html = Handlebars.templates.editor_block_template(context2);
            blocks_wrapper.append(html);
        }
    });


    $(blocks_wrapper).on("click", "#delete", function (e) {
        e.preventDefault();
        if (blocks_counter > 1) {
            $(this).parent('div').parent('div').remove();
            blocks_counter--;
        }
    });

    $(blocks_wrapper).on('change', "#cmd-select", function (event) {
        var block = blks[event.target.value];
        document.getElementById("input-E-" + event.target.name).value = block["E_name"] + "_" + event.target.name;
        document.getElementById("input-F-" + event.target.name).value = block["F_name"] + "_" + event.target.name;
        document.getElementById("input-Q-" + event.target.name).value = block["Q_name"] + "_" + event.target.name;
        document.getElementById("input-K-" + event.target.name).value = block["K_name"] + "_" + event.target.name;
        document.getElementById("help-label-" + event.target.name).textContent = block["Help_ENG"];
    });

    var sysvar_wrapper = $("#sysvar-form");
    var add_sysvar_button = $(".add_sysvar_btn");
    var sysvar = response["sysvar"];
    var sysvar_counter = 1;
    var sysvar_context = {
        sysvar: sysvar,
        idx: sysvar_counter
    };
    var sysvar_template = Handlebars.compile($("#sysvar-template").html());
    var sysvar_html = sysvar_template(sysvar_context);
    sysvar_wrapper.append(sysvar_html);

    $(add_sysvar_button).click(function (e) {
        e.preventDefault();
        if (sysvar_counter < max_fields) {
            sysvar_counter++;
            var sysvar_context2 = {
                sysvar: sysvar,
                idx: sysvar_counter
            };
            var sysvar_template = Handlebars.compile($("#sysvar-template").html());
            var sysvar_html = sysvar_template(sysvar_context2);
            sysvar_wrapper.append(sysvar_html);
        }
    });


    $(sysvar_wrapper).on("click", "#delete-sysvar", function (e) {
        e.preventDefault();
        if (sysvar_counter > 1) {
            $(this).parent('div').parent('div').remove();
            sysvar_counter--;
        }
    });

    $(sysvar_wrapper).on('change', "#sysvar-select", function (event) {
        var sysv = sysvar[event.target.value];
        var help =$("#sysvar-help-label-" + event.target.name);
        help.text(sysv["Help_ENG"]);
    });

}

function coordinates() {
    var coord_counter = 1;
    var coord_template = Handlebars.compile($("#coord-template").html());
    var coord_html = coord_template({idx: coord_counter});
    var coord_wrapper = $("#coord-form");
    $("#add_coord_btn").click(function (e) {
        e.preventDefault();
        if (coord_counter < 100) {
            coord_counter++;
            coord_wrapper.append(coord_html)
        }
    });
    $(wrapper).on("click", "#delete-coord", function (e) {
        e.preventDefault();
        if (coord_counter > 1) {
            $(this).parent('div').parent('div').remove();
            coord_counter--;
        }
    });
}