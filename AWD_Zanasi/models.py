# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models


class Project(models.Model):
    matlab_file = models.FileField(upload_to='matlab_projects/%Y/%m/%d/')
    proj_desc = models.CharField(max_length=400)
    res_type = models.CharField(max_length=3, verbose_name='Resolution Type')
    launch_date = models.DateField(verbose_name='Launch Date')

    # accounting_data = ???

    def __str__(self):
        return self.matlab_file.name


class ProjectOutput(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    txt = models.TextField()
    img = models.ImageField()

    def __str__(self):
        return self.txt