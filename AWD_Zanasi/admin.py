# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.conf.urls import url
from django.contrib import admin
from django.template.response import TemplateResponse

from .models import *

# Register your models here.
admin.site.register(Project)
admin.site.register(ProjectOutput)
# commands
admin.site.register(CommandBranch)
admin.site.register(CommandBlock)
admin.site.register(CommandSystem)

#
#
# class MyModelAdmin(admin.ModelAdmin):
#     def get_urls(self):
#         urls = super(MyModelAdmin, self).get_urls()
#         my_urls = [
#             url(r'^updatecommands/$', self.update_commands, name='update_commands'),
#         ]
#         return my_urls + urls
#
#     def update_commands(self, request):
#
#         context = dict(
#             self.admin_site.each_context(request)
#         )
#         return TemplateResponse(request, "admin/AWD_Zanasi/updatecommands.html", context)
