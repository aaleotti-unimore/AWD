# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib.auth.models import User
from django.db import models
from django.conf import settings


class Project(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, default='admin')
    matlab_file = models.FileField(upload_to='matlab_projects/%Y/%m/%d/')
    proj_desc = models.CharField(max_length=400, blank=True, null=True)
    res_type = models.CharField(max_length=3, verbose_name='Resolution Type')
    launch_date = models.DateField(verbose_name='Launch Date', blank=True, null=True)

    # accounting_data = ???

    def __str__(self):
        return self.matlab_file.name


class ProjectOutput(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    txt = models.TextField(blank=True, null=True)
    img = models.ImageField(blank=True, null=True)

    def __str__(self):
        return self.txt
