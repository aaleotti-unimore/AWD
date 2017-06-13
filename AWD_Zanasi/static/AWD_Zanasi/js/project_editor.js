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

    function csrfSafeMethod(method) {
        // these HTTP methods do not require CSRF protection
        return (/^(GET|HEAD|OPTIONS|TRACE)$/.test(method));
    }

});

function handle_response(response) {

    var max_fields = 100;
    var wrapper = $("#blocks-form");
    var add_block_button = $(".add_block_btn");
    var add_coord_button = $(".add_coord_btn");
    var blks = response["blocks"];
    var blocks_counter = 1;
    var context = {
        blocks: blks,
        idx: blocks_counter
    };
    var template = Handlebars.templates.editor_block_template(context);
    wrapper.append(template);

    $(add_block_button).click(function (e) {
        e.preventDefault();
        if (blocks_counter < max_fields) {
            blocks_counter++;
            var context2 = {
                blocks: blks,
                idx: blocks_counter
            };
            var html = Handlebars.templates.editor_block_template(context2);
            wrapper.append(html);
        }
    });


    $(wrapper).on("click", "#delete", function (e) {
        e.preventDefault();
        if (blocks_counter > 1) {
            $(this).parent('div').parent('div').remove();
            blocks_counter--;
        }
    });

    $(wrapper).on('change', "#cmd-select", function (event) {
        console.log('Event ' + event.target.id + ' target value', event.target.value);
        var block = blks[event.target.value];
        document.getElementById("input-E-" + event.target.name).value = block["E_name"] + "_" + event.target.name;
        document.getElementById("input-F-" + event.target.name).value = block["F_name"] + "_" + event.target.name;
        document.getElementById("input-Q-" + event.target.name).value = block["Q_name"] + "_" + event.target.name;
        document.getElementById("input-K-" + event.target.name).value = block["K_name"] + "_" + event.target.name;
    });

}
