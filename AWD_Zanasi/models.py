# -*- coding: utf-8 -*-
from __future__ import unicode_literals
from django.core.files.base import ContentFile
from django.core.files import File

from django.conf import settings
from django.contrib.auth.models import User
from django.db import models


def matlab_file_path(instance, filename):
    # file will be uploaded to MEDIA_ROOT/user_<id>/<project_name>/<filename>
    return 'user_{0}/{1}/{2}'.format(instance.user.username, instance.name, filename)


def project_output_path(instance, filename):
    # file will be uploaded to MEDIA_ROOT/user_<id>/<project_name>/out/<filename>
    return 'user_{0}/{1}/out/{2}'.format(instance.project.user.username, instance.project.name, filename)


class Project(models.Model):
    name = models.CharField(max_length=200, default='project')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, default='admin')
    matlab_file = models.FileField(upload_to=matlab_file_path)
    proj_desc = models.CharField(max_length=400, blank=True, null=True)
    launch_date = models.DateTimeField(verbose_name='Launch Date', blank=True,
                                       null=True)

    def save_text_file(self, content):
        self.matlab_file = ContentFile(content)

    def display_source_file(self):
        with open(self.matlab_file.path) as fp:
            return fp.read()

    def __str__(self):
        return self.name


class ProjectOutput(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    text_file = models.FileField(upload_to=project_output_path, blank=True, null=True)
    image_file = models.ImageField(upload_to=project_output_path, blank=True, null=True)

    def __str__(self):
        if self.text_file:
            return self.text_file.url
        else:
            if self.image_file:
                return self.image_file.url
            else:
                return self.project.name

    def display_text_file(self):
        with open(self.text_file.path) as fp:
            return fp.read()

    def save_image(self, filename, filepath):
        with open(filepath, 'rb') as doc_file:
            self.image_file.save(filename, File(doc_file), save=True)

    def save_text(self, filename, filepath):
        with open(filepath, 'rb') as doc_file:
            self.text_file.save(filename, File(doc_file), save=True)


class Command(models.Model):
    Sigla = models.CharField(max_length=16)
    Help_ENG = models.CharField(max_length=400, blank=True, null=True)
    Help = models.CharField(max_length=400, blank=True, null=True)

    class Meta:
        abstract = True


class CommandBranch(Command):
    # Nome, Value, Sigla, StrNum, Vincoli, Range, Type, Help, Help_ENG
    Nome = models.CharField(max_length=16, blank=True, null=True)
    Value = models.CharField(max_length=16, blank=True, null=True)
    StrNum = models.CharField(max_length=16, blank=True, null=True)
    Vincoli = models.CharField(max_length=16, blank=True, null=True)
    Range = models.CharField(max_length=48, blank=True, null=True)
    Type = models.CharField(max_length=16, blank=True, null=True)


class CommandBlock(Command):
    # Sigla, Tipo_di_Ramo, Diretto, Out, E_name, K_name, Q_name, F_name, Help, Comandi, Help_ENG
    Tipo_di_Ramo = models.CharField(max_length=16, blank=True, null=True)
    Diretto = models.CharField(max_length=16, blank=True, null=True)
    Out = models.CharField(max_length=16, blank=True, null=True)
    E_name = models.CharField(max_length=16, blank=True, null=True)
    K_name = models.CharField(max_length=16, blank=True, null=True)
    Q_name = models.CharField(max_length=16, blank=True, null=True)
    F_name = models.CharField(max_length=16, blank=True, null=True)
    Comandi = models.CharField(max_length=16, blank=True, null=True)


class CommandSystem(CommandBranch):
    # Nome, Value, Sigla, StrNum, Vincoli, Range, Type, Help, Help_ENG
    pass
