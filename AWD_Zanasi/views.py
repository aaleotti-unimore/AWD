# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import logging

from django.shortcuts import render, redirect, HttpResponse, HttpResponseRedirect
from django.contrib import messages
from django.contrib.auth.decorators import user_passes_test

from .forms import NewProjectForm, EditProjectForm, LoadCommandsListForm
from .models import *
from pprint import pprint
import csv, codecs

# Create your views here.
logger = logging.getLogger(__name__)


def index(request):
    if request.user.is_authenticated:
        if request.user.is_superuser:
            projects = Project.objects.all()
            results = ProjectOutput.objects.all()
        else:
            projects = Project.objects.filter(user=request.user)
            results = ProjectOutput.objects.filter(project__in=projects)
        return render(request, 'AWD_Zanasi/home.html',
                      {
                          'projects': projects,
                          'project_outputs': results
                      }
                      )
    return render(request, 'AWD_Zanasi/home.html')


def create_project(request):
    if request.method == 'POST':
        form = NewProjectForm(request.POST, request.FILES)
        if form.is_valid():
            new_project = Project(
                name=form.cleaned_data["Sigla"],
                user=request.user,
                matlab_file=form.cleaned_data['matlab_file'],
                proj_desc=form.cleaned_data['proj_desc'],
                res_type=form.cleaned_data['res_type']
            )
            new_project.save()
            return redirect('index')
    else:
        HttpResponse(request, 'ERROR')

    return render(request, 'AWD_Zanasi/projects/createproject.html', {'form': NewProjectForm()})


def project_results(request, project_id):
    if project_id:
        project = Project.objects.get(id=project_id)
        output = ProjectOutput.objects.filter(project=project)
        if project:
            return render(request, 'AWD_Zanasi/projects/projectresults.html',
                          {'project': project, 'project_output': output})
    return redirect('index')


def edit_project(request, project_id):
    if project_id:
        project = Project.objects.get(id=project_id)

        if request.method == 'POST':
            form = EditProjectForm(request.POST)
            if form.is_valid():
                filename = project.matlab_file.path

                with open(filename, 'r+') as f:
                    f.seek(0)
                    f.write(form.cleaned_data['proj_desc'])
                    f.truncate()

                project.save()
                messages.add_message(request, messages.SUCCESS, 'Project successfully edited')
                return redirect('index')
            else:
                messages.add_message(request, messages.ERROR, 'Error Editing Project')
                return redirect('edit_project', project_id)

        if project:
            form = EditProjectForm(initial={'proj_desc': project.display_source_file()})
            return render(request, 'AWD_Zanasi/projects/editproject.html',
                          {'project': project, 'form': form})

    return redirect('index')


def delete_project(request, project_id):
    if request.method == 'POST':
        if project_id:
            project = Project.objects.get(id=project_id)
            if project:
                project.delete()
                messages.add_message(request, messages.SUCCESS, 'Project successfully deleted')
            else:
                messages.add_message(request, messages.ERROR, 'Project not found')
        else:
            messages.add_message(request, messages.ERROR, 'Project id not valid')

    return redirect('index')


@user_passes_test(lambda u: u.is_superuser)
def update_commands(request):
    import io
    cmd_list = []
    form = LoadCommandsListForm()
    if request.method == 'POST':
        form = LoadCommandsListForm(request.POST, request.FILES)
        if form.is_valid():
            csvfile = request.FILES['commands_list']
            dialect = csv.Sniffer().sniff(codecs.EncodedFile(csvfile, "iso-8859-1").readline())
            csvfile.open()
            reader = csv.reader(codecs.EncodedFile(csvfile, "iso-8859-1"), delimiter=str(u','), dialect=dialect)
            for row in reader:
                print(row)

    return render(request, 'AWD_Zanasi/updatecommands.html', {'form': form, 'commands': cmd_list})
