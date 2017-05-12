# -*- coding: utf-8 -*-
from crispy_forms.helper import FormHelper
from crispy_forms.layout import Layout, Div, Submit, HTML, Button, Row, Field
from crispy_forms.bootstrap import AppendedText, PrependedText, FormActions
from django import forms


class NewProjectForm(forms.Form):
    name = forms.CharField(label='Project Name', max_length=200)
    matlab_file = forms.FileField()
    proj_desc = forms.CharField(widget=forms.Textarea)
    res_type = forms.ChoiceField(widget=forms.RadioSelect())
