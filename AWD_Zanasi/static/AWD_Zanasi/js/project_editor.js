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

    $(document).on("click", "#submitall", function (event) {
        var empty = $(document).find("input").not("#input-E, #input-F, #input-K, #input-Q").filter(function () {
            return this.value === "";
        });
        if (empty.length) {
            //At least one input is empty
            alert("Please fill all the required inputs")
        } else {
            $('#allforms').submit();
        }
    })

});

function handle_response(response) {
    // --------------- BLOCKS
    var lang = navigator.language || navigator.userLanguage;
    var max_fields = 100;
    var blocks_wrapper = $("#blocks-form");
    var add_block_button = $(".add_block_btn");
    var blks = response["blocks"];
    var blocks_counter = 0;
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
        var blockrow = $(this).closest("#blockrow");
        e.preventDefault();
        if (blocks_counter > 0) {
            blockrow.nextUntil("#blockrow").addBack().remove();
            // blockrow.empty();
            blocks_counter--;
        }
    });

    $(blocks_wrapper).on('change', "#cmd-select", function (event) {
        var block = blks[event.target.value];
        var rowblock = $(this).parent('div').parent('div');
        var index = event.target.getAttribute("tabindex");
        rowblock.find('#input-E').attr("placeholder", block["E_name"]);
        rowblock.find('#input-F').attr("placeholder", block["F_name"]);
        rowblock.find('#input-Q').attr("placeholder", block["Q_name"]);
        rowblock.find('#input-K').attr("placeholder", block["K_name"]);
        var help = block["Help_ENG"];
        if (lang === "it") {
            help = block["Help"];
        }
        rowblock.find('#help-label').text(help);
    });


    // --------------- SYSVAR

    var sysvar_wrapper = $("#sysvar-form");
    var add_sysvar_button = $(".add_sysvar_btn");
    var sysvar = response["sysvar"];
    var sysvar_counter = 0;

    $(add_sysvar_button).click(function (e) {
        e.preventDefault();
        $("#sysvar-table-titles").show();
        if (sysvar_counter < max_fields) {
            var sysvar_context2 = {
                sysvar: sysvar,
                idx: sysvar_counter
            };
            var sysvar_template = Handlebars.compile($("#sysvar-template").html());
            var sysvar_html = sysvar_template(sysvar_context2);
            sysvar_wrapper.append(sysvar_html);
            sysvar_counter++;
        }
    });


    $(sysvar_wrapper).on("click", "#delete-sysvar", function (e) {
        e.preventDefault();
        if (sysvar_counter > 0) {
            $(this).parent('div').parent('div').remove();
            sysvar_counter--;
        }
        if (sysvar_counter == 0) {
            $("#sysvar-table-titles").hide()
        }
    });

    $(sysvar_wrapper).on('change', "#sysvar-select", function (event) {
        var sysv = sysvar[event.target.value];
        var help = $(this).parent('div').parent('div').find('#sysvar-help-label');
        // var help = $("#sysvar-help-label-" + event.target.name);
        var help_text = sysv["Help_ENG"];
        if (lang === "it") {
            help_text = sysv["Help"];
        }
        help.text(help_text);
        help.show();
        $(this).parent('div').parent('div').find('#sysvar-range').attr("placeholder", sysv["Range"])
    });

    // ----------- BRANCHES


    var branch = response["branches"];
    var branch_counter = 0;

    $(document).on("click", "#add-branch-button", function (e) {
        e.preventDefault();
        var block_n = $(this).attr("tabindex");
        if (branch_counter < max_fields) {
            var branch_context2 = {
                branches: branch,
                idx: branch_counter,
                block_n: block_n
            };
            branch_counter++;
            var branch_template = Handlebars.compile($("#branch-template").html());
            var branch_html = branch_template(branch_context2);
            $(this).parent('div').parents('.row:first').after(branch_html);
        }
    });


    $(document).on("click", "#delete-branch", function (e) {
        e.preventDefault();
        if (branch_counter > 0) {
            $(this).parent('div').parent('div').remove();
            branch_counter--;
        }
    });

    $(document).on('change', "#branch-select", function (event) {
        var sysv = branch[event.target.value];
        var help = $(this).parent('div').parent('div').find('#branch-help-label');
        var help_text = sysv["Help_ENG"];
        if (lang === "it") {
            help_text = sysv["Help"];
        }
        help.text(help_text);
        help.show();
        $(this).parent('div').parent('div').find('#branch-range').attr("placeholder", sysv["Range"])
    });


}

function coordinates() {
    var coord_counter = 0;
    var coord_template = Handlebars.compile($("#coord-template").html());
    var coord_html = coord_template({idx: coord_counter});
    var coord_wrapper = $("#coord-form");
    coord_wrapper.append(coord_html);

    $("#add_coord_btn").click(function (e) {
        e.preventDefault();
        if (coord_counter < 100) {
            coord_counter++;
            coord_html = coord_template({idx: coord_counter});
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

