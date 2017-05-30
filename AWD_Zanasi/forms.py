# -*- coding: utf-8 -*-
from crispy_forms.bootstrap import FormActions
from crispy_forms.helper import FormHelper
from crispy_forms.layout import Layout, Submit
from django import forms


class NewProjectForm(forms.Form):
    name = forms.CharField(
        label='Project Name',
        max_length=200,
    )

    matlab_file = forms.FileField(
        label="Project File",
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
            Submit('cancel', 'Cancel', onclick='history.go(-1);'),
        )
    )


class EditProjectForm(forms.Form):
    proj_desc = forms.CharField(
        widget=forms.Textarea(attrs={'cols': 30, 'rows': 20}),
        label='Project Code',
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
        'proj_desc',
        FormActions(
            Submit('save_changes', 'Save changes', css_class="btn-primary"),
            Submit('cancel', 'Cancel', onclick='history.go(-1);'),
        )
    )


class LoadCommandsListForm(forms.Form):
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
            Submit('cancel', 'Cancel', onclick='history.go(-1);'),
        )
    )
