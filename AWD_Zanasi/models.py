# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.conf import settings
from django.contrib.auth.models import User
from django.core.files import File
from django.core.files.base import ContentFile
from django.db import models


def matlab_file_path(instance, filename):
    """
    defines the path of the uploaded matlab file for :model:`AWD_Zanasi.Project`
    It will be uploaded to MEDIA_ROOT/user_<id>/<project_name>/<filename>
    """
    return 'user_{0}/{1}/{2}'.format(instance.user.username, instance.name, filename)


def project_output_path(instance, filename):
    """
    defines the path of the output files for :model:`AWD_Zanasi.ProjectOutput`
    # file will be uploaded to MEDIA_ROOT/user_<id>/<project_name>/out/<filename>
    """
    return 'user_{0}/{1}/out/{2}'.format(instance.project.user.username, instance.name, filename)


    
    
class Project(models.Model):
    """
    Stores a single Project entry. it's definied by its name, user and a txt file containing the matlab code.
    Other fields ar optional or automatically generated.
    """
    name = models.CharField(max_length=200, default='project', help_text='Project name')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, default='admin')
    matlab_file = models.FileField(upload_to=matlab_file_path, help_text="Matlab POG code file",  blank=True, null=True)
    proj_desc = models.CharField(max_length=400, blank=True, null=True, help_text="Project description")
    launch_date = models.DateTimeField(verbose_name='Launch Date', blank=True,
                                       null=True, help_text='Project last execution date')
    is_example = models.BooleanField(default=False,
                                     help_text='Used only by an Admin user to mark a project as an example for users.')

    def save_text_file(self, content):
        """
        Saves a text file from a string content of a :model:`AWD_Zanasi.Project` matlab file 
        """
        self.matlab_file = ContentFile(content)

    def display_source_file(self):
        """
        Reads the content of a :model:`AWD_Zanasi.Project` matlab_file
        """
        with open(self.matlab_file.path) as fp:
            text = fp.read()
            # fp.truncate()

        return text


    def __str__(self):
        return self.name
        
    
    def save(self, *args, **kwargs):
        self.full_clean() #full validation and clean
        if not self.id:
             self.name = self.name.replace(' ','_')
        super(Project, self).save(*args, **kwargs)
        
    def clean(self):
        if self.name:
            self.name = self.name.replace(' ','_')
            
    def project_folder(self):
        return 'user_{0}\\{1}'.format(self.project.user.username, self.project.name)


class ProjectOutput(models.Model):
    """
    Output files for a :model:`AWD_Zanasi.Project` . 
    """
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    text_file = models.FileField(upload_to=project_output_path, blank=True, null=True,
                                 help_text="Use only for text files")
    image_file = models.ImageField(upload_to=project_output_path, blank=True, null=True,
                                   help_text="Use only for image files")
    generic_file = models.FileField(upload_to=project_output_path, blank=True, null=True,
                                 help_text="Generic Type file" )
	
	
    def __str__(self):
        if self.text_file:
            return self.text_file.url
        else:
            if self.image_file:
                return self.image_file.url
            else:
                return self.project.name

    def display_text_file(self):
        """
        Reads a :model:`AWD_Zanasi.ProjectOutput` text file.
        """
        with open(self.text_file.path) as fp:
            return fp.read()

    def save_image(self, filename, filepath):
        """
        Saves a image from a path into the upload folder
        """
        with open(filepath, 'rb') as doc_file:
            self.image_file.save(filename, File(doc_file), save=True)

    def save_text(self, filename, filepath):
        """
        saves a text file from a path into the upload folder
        """
        with open(filepath, 'rb') as doc_file:
            self.text_file.save(filename, File(doc_file), save=True)


class Command(models.Model):
    """
    POG command abstract model. it's never directly referenced, only inherited by its childs.
    """
    Sigla = models.CharField(max_length=16)
    Help_ENG = models.CharField(max_length=400, blank=True, null=True)
    Help = models.CharField(max_length=400, blank=True, null=True)

    class Meta:
        abstract = True


class CommandBranch(Command):
    """
    Intherits from :model:`AWD_Zanasi.Command`. Defines a model for a Branch (Ramo) type of POG commands. 
    The CSV files for database uploads must contains those fields: Nome, Value, Sigla, StrNum, Vincoli, Range, Type, Help, Help_ENG
    """
    Nome = models.CharField(max_length=16, blank=True, null=True)
    Value = models.CharField(max_length=16, blank=True, null=True)
    StrNum = models.CharField(max_length=16, blank=True, null=True)
    Vincoli = models.CharField(max_length=16, blank=True, null=True)
    Range = models.CharField(max_length=48, blank=True, null=True)
    Type = models.CharField(max_length=16, blank=True, null=True)


class CommandBlock(Command):
    """
    Intherits from :model:`AWD_Zanasi.Command`.
    Defines a model for a Block (Blocco) type of POG commands. 
    The CSV files for database uploads must contains those fields: Sigla, Tipo_di_Ramo, Diretto, Out, E_name, K_name, Q_name, F_name, Help, Comandi, Help_ENG
    """
    Tipo_di_Ramo = models.CharField(max_length=16, blank=True, null=True)
    Diretto = models.CharField(max_length=16, blank=True, null=True)
    Out = models.CharField(max_length=16, blank=True, null=True)
    E_name = models.CharField(max_length=16, blank=True, null=True)
    K_name = models.CharField(max_length=16, blank=True, null=True)
    Q_name = models.CharField(max_length=16, blank=True, null=True)
    F_name = models.CharField(max_length=16, blank=True, null=True)
    Comandi = models.CharField(max_length=16, blank=True, null=True)


class CommandSystem(CommandBranch):
    """
    Intherits from :model:`AWD_Zanasi.Command`.
    Placeholder for a System (Sistema) type of POG commands. It's the same as a :model:`AWD_Zanasi.CommandBranch` model but alread defined for future improvements
    
    The CSV files for database uploads must contains those fields: Nome, Value, Sigla, StrNum, Vincoli, Range, Type, Help, Help_ENG
   
    """
    pass
