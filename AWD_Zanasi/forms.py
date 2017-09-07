# -*- coding: utf-8 -*-
from crispy_forms.bootstrap import FormActions
from crispy_forms.helper import FormHelper
from crispy_forms.layout import Layout, Submit, Button
from django import forms


class NewProjectForm(forms.Form):
    """
    Crispy Forms object for a new :model:`AWD_Zanasi.Project` form. The helper object defines the graphical layout of the form.
    Used inside  :template:`AWD_Zanasi/projects/create_project.html`
    """

    name = forms.CharField(
        label='Project Name',
        max_length=200,
    )

    matlab_file = forms.FileField(
        label="Project File",
        required=False
    )

    proj_desc = forms.CharField(
        widget=forms.Textarea(),
        label='Project Description',
        required=False
    )

    helper = FormHelper()
    helper.form_action = 'create_project'
    helper.form_method = 'POST'
    helper.form_class = 'form-horizontal'
    helper.label_class = 'col-lg-2'
    helper.field_class = 'col-lg-8'
    helper.layout = Layout(
        'name',
        'matlab_file',
        'proj_desc',
        FormActions(
            Submit('save_changes', 'Save changes', css_class="btn-primary"),
            Button('cancel', 'Cancel', onclick="javascript:location.href = '/pogmodeler';"),
        )
    )


class EditProjectForm(forms.Form):
    """
    Crispy Forms object to edit a :model:`AWD_Zanasi.Project`. The helper object defines the graphical layout of the form
    Used inside  :template:`AWD_Zanasi/projects/edit_project.html`
    """
    proj_name = forms.CharField(required=True, label="Project Name")
    proj_code = forms.CharField(
        widget=forms.Textarea(attrs={'cols': 30, 'rows': 20}),
        label='Project Code',
        required=False,
        # strip=False
    )
    proj_desc = forms.CharField(
        widget=forms.Textarea(attrs={'cols': 30, 'rows': 3}),
        label='Project Description',
        required=False,
        # strip=False
    )

    helper = FormHelper()
    helper.form_tag = False
    helper.form_action = 'create_project'
    helper.form_method = 'POST'
    helper.form_class = 'form-horizontal'
    helper.label_class = 'col-lg-2'
    helper.field_class = 'col-lg-8'
    helper.layout = Layout(
        'proj_name',
        'proj_code',
        'proj_desc',
        FormActions(
            Submit('save_changes', 'Save changes', css_class="btn-primary"),
            Button('cancel', 'Cancel', onclick="javascript:location.href = '/pogmodeler';"),
        )
    )


class LoadCommandsListForm(forms.Form):
    """
     Crispy Forms object for to upade :model:`AWD_Zanasi.Command` . The helper object defines the graphical layout of the form.
     Used inside  :template:`AWD_Zanasi/updatecommands.html`
     """
    blocks_list = forms.FileField(
        label="Blocks command List",
        required=False,
    )

    branches_list = forms.FileField(
        label="Branches command List",
        required=False,

    )
    system_list = forms.FileField(
        label="System command List",
        required=False,

    )

    helper = FormHelper()
    helper.form_action = 'update_commands'
    helper.form_method = 'POST'
    helper.form_class = 'form-horizontal'
    helper.label_class = 'col-lg-2'
    helper.field_class = 'col-lg-8'
    helper.layout = Layout(
        'blocks_list',
        'branches_list',
        'system_list',
        FormActions(
            Submit('save_changes', 'Submit List', css_class="btn-primary"),
            Button('cancel', 'Cancel', onclick='history.go(-1);'),
        )
    )
