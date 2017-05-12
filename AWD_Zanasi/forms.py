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

    res_type = forms.ChoiceField(
        choices=(
            ('NUM', "Numerical"),
            ('SYM', "Symbolical")
        ),
        widget=forms.RadioSelect,
        initial='NUM',
        label="Resolution Type",
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
        'res_type',
        FormActions(
            Submit('save_changes', 'Save changes', css_class="btn-primary"),
            Submit('cancel', 'Cancel', onclick='history.go(-1);'),
        )
    )
