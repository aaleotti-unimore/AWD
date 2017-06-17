# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.conf.urls import url
from django.contrib import admin
from django.template.response import TemplateResponse

from .models import *

# Register your models here.
admin.site.register(Project)
admin.site.register(ProjectOutput)

