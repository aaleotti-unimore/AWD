# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.conf import settings
from django.contrib.auth.models import User
from django.db import models


class Project(models.Model):
    name = models.CharField(max_length=200, default='project')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, default='admin')
    matlab_file = models.FileField(upload_to='matlab_projects/%Y/%m/%d/')
    proj_desc = models.CharField(max_length=400, blank=True, null=True)
    res_type = models.CharField(max_length=3, verbose_name='Resolution Type')
    launch_date = models.DateField(verbose_name='Launch Date', blank=True, null=True)

    def display_source_file(self):
        with open(self.matlab_file.path) as fp:
            return fp.read()

    def __str__(self):
        return self.name


class ProjectOutput(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    text_file = models.FileField(upload_to='matlab_projects/%Y/%m/%d/', blank=True, null=True)
    image_file = models.ImageField(upload_to='matlab_projects/%Y/%m/%d/', blank=True, null=True)

    def __str__(self):
        if self.text_file:
            return self.text_file.name
        else:
            if self.image_file:
                return self.image_file.name
            else:
                return self.project.name

    def display_text_file(self):
        with open(self.text_file.path) as fp:
            return fp.read()


class Command(models.Model):
    name = models.TextField(max_length=8)
    default_value = models.TextField(max_length=16, blank=True, null=True)
    description_eng = models.TextField(max_length=400, blank=True, null=True)
    description_ita = models.TextField(max_length=400, blank=True, null=True)

    class Meta:
        abstract = True


class CommandBranch(Command):
    pass


class CommandBlock(Command):
    pass


class CommandMetaBlock(Command):
    pass


class CommandSystem(Command):
    pass
