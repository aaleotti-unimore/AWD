$(document).ready(populateBlocks);

function populateBlocks() {
    $.ajax({
        url: '/pogmodeler/projects/create_project/editor/',
        type: 'POST',
        dataType: 'json',
        success: function (response) {
            console.log(response)
            // var form = $('#generator-form');
            // var source = $("#new-block-template").html();
            // var newblocktemplate = Handlebars.compile(source);
            // var html = newblocktemplate();
            // form.append(html)
        },
        error: function (xhr, err) {
            console.log("readyState: " + xhr.readyState + "\nstatus: " + xhr.status);
            console.log("responseText: " + xhr.responseText);
        }
    });
}