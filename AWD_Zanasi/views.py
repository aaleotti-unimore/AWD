# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import csv
import logging

from django.contrib import messages
from django.contrib.auth.decorators import user_passes_test
from django.http import JsonResponse
from django.shortcuts import render, redirect, HttpResponse

from .forms import NewProjectForm, EditProjectForm, LoadCommandsListForm
from .models import *

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
                name=form.cleaned_data['name'],
                user=request.user,
                matlab_file=form.cleaned_data['matlab_file'],
                proj_desc=form.cleaned_data['proj_desc'],
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


# noinspection PyCompatibility
@user_passes_test(lambda u: u.is_superuser)
def update_commands(request):
    cmd_list = []
    form = LoadCommandsListForm()
    if request.method == 'POST':
        form = LoadCommandsListForm(request.POST, request.FILES)
        if form.is_valid():
            if 'blocks_list' in request.FILES:
                csvfile = request.FILES['blocks_list']

                # try:
                cmd_list = csv.DictReader(csvfile, delimiter=str(u';'), dialect=csv.excel)

                CommandBlock.objects.all().delete()

                for row in cmd_list:
                    cmd = CommandBlock(
                        Sigla=unicode(row['Sigla']),
                        Tipo_di_Ramo=unicode(row['Tipo_di_Ramo']),
                        Diretto=row['Diretto'],
                        Out=unicode(row['Out']),
                        E_name=unicode(row['E_name']),
                        K_name=unicode(row['K_name']),
                        Q_name=unicode(row['Q_name']),
                        F_name=unicode(row['F_name']),
                        Help=unicode(row['Help']),
                        Help_ENG=unicode(row['Help_ENG']),
                        Comandi=unicode(row['Comandi']),
                    )
                    cmd.save()

                messages.add_message(request, messages.SUCCESS, u'Blocks Commands Successfully Updated')

            if 'branches_list' in request.FILES:
                csvfile = request.FILES['branches_list']
                cmd_list = csv.DictReader(csvfile, delimiter=str(u';'), dialect=csv.excel)

                CommandBranch.objects.all().delete()

                for row in cmd_list:
                    cmd = CommandBranch(
                        # Nome, Value, Sigla, StrNum, Vincoli, Range, Type, Help, Help_ENG
                        Nome=unicode(row['Nome']),
                        Value=unicode(row['Value']),
                        Sigla=unicode(row['Sigla']),
                        StrNum=unicode(row['StrNum']),
                        Vincoli=unicode(row['Vincoli']),
                        Range=unicode(row['Range']),
                        Type=unicode(row['Type']),
                        Help=unicode(row['Help']),
                        Help_ENG=unicode(row['Help_ENG']),
                    )
                    cmd.save()

                messages.add_message(request, messages.SUCCESS, u'Branches Commands Successfully Updated')

            if 'system_list' in request.FILES:
                csvfile = request.FILES['system_list']
                cmd_list = csv.DictReader(csvfile, delimiter=str(u';'), dialect=csv.excel)

                CommandSystem.objects.all().delete()

                for row in cmd_list:
                    cmd = CommandSystem(
                        # Nome, Value, Sigla, StrNum, Vincoli, Range, Type, Help, Help_ENG
                        Nome=unicode(row['Nome']),
                        Value=unicode(row['Value']),
                        Sigla=unicode(row['Sigla']),
                        StrNum=unicode(row['StrNum']),
                        Vincoli=unicode(row['Vincoli']),
                        Range=unicode(row['Range']),
                        Type=unicode(row['Type']),
                        Help=unicode(row['Help']),
                        Help_ENG=unicode(row['Help_ENG']),
                    )
                    cmd.save()

                messages.add_message(request, messages.SUCCESS, u'System Commands Successfully Updated')

    return render(request, 'AWD_Zanasi/updatecommands.html',
                  {'form': form})  # noinspection PyCompatibility


def help_page(request):
    blocks = CommandBlock.objects.all()
    system = CommandSystem.objects.all()
    branches = CommandBranch.objects.all()

    return render(request, 'AWD_Zanasi/help.html',
                  {"blocks": blocks,
                   "branches": branches,
                   "system": system})


def project_editor(request):
    blocks = CommandBlock.objects.values("Sigla", "E_name", "K_name", "Q_name", "F_name", "Help", "Help_ENG")
    system = CommandSystem.objects.values("Nome", "Range", "Help_ENG", "Help")
    branches = CommandBranch.objects.values("Nome", "Range", "Help_ENG", "Help")
    if request.method == 'POST':
        return JsonResponse({'blocks': list(blocks), 'sysvar': list(system), "branches": list(branches)})

    return render(request, 'AWD_Zanasi/projects/newprojecteditor.html')


from pprint import pprint


def project_editor_response(request):
    if request.method == 'POST':
        for key, value in request.POST.items():
            print(key, value)
        return HttpResponse("OK")
    return HttpResponse("Not Ok")
