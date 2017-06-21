# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import csv
import logging

from django.contrib import messages
from django.contrib.auth.decorators import user_passes_test
from django.db import IntegrityError
from django.http import JsonResponse
from django.shortcuts import render, redirect, HttpResponse

from watchdog_handler import MyHandler
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
        outs = list(output)
        for out in outs:
            print("file output url: " + str(out))

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


def project_editor_response(request):
    blocks_obj = list(CommandBlock.objects.values("Sigla"))
    branches_obj = list(CommandBranch.objects.values("Sigla"))
    sysvar_obj = list(CommandSystem.objects.values("Sigla"))
    if request.method == 'POST':
        blk = {}  # blocks dictionary
        brnch = {}  # branches dictionary
        ssvr = {}  # sysvars dictionary
        nds = {}  # nodes dictionary

        blocks_str = ""
        sysvar_str = ""
        node_str = "*P"

        # commands dictionaries generation
        for key, value in request.POST.items():
            if value and (not key == 'csrfmiddlewaretoken'):
                if key.startswith("cmd_select"):
                    blk[key] = value
                if key.startswith("branch_select"):
                    brnch[key] = value
                if key.startswith("sysvar_select"):
                    ssvr[key] = value
                if key.startswith("coord_name"):
                    nds[key] = value

        # sysvars
        for key, value in ssvr.iteritems():
            type, attr, index = key.split("_")
            s_str = "\'**, %s, %s\'" % (
                str(sysvar_obj[int(value)]['Sigla']), str(request.POST['sysvar_range_' + index]))
            sysvar_str += s_str + "\n"

        # nodes
        for key, value in nds.iteritems():
            # esample  *P, A=(1+1i*1.5), 1=(2+1i*5), c=(-1+1i*3)
            type, attr, index = key.split("_")
            node_str += ", %s=(%s+1i*%s)" % (value, request.POST["coord_x_" + index], request.POST["coord_y_" + index])

        node_str = "\'" + node_str + "\'\n"

        # blocks commands generation
        for key, value in blk.iteritems():
            type, attr, index = key.split("_")  # example cmd_select_1
            k_n, q_n, e_n, f_n = ["", "", "", ""]

            select = blocks_obj[int(value)]['Sigla'] + ", "
            nodes = request.POST['cmd_node-1_' + index] + ", " + request.POST['cmd_node-2_' + index]
            if request.POST['cmd_input-K_' + index]:
                k_n = ", Kn, " + request.POST['cmd_input-K_' + index]

            if request.POST['cmd_input-E_' + index]:
                e_n = ", En, " + request.POST['cmd_input-E_' + index]

            if request.POST['cmd_input-F_' + index]:
                f_n = ", Fn, " + request.POST['cmd_input-F_' + index]

            if request.POST['cmd_input-Q_' + index]:
                q_n = ", Qn, " + request.POST['cmd_input-Q_' + index]

            branches_str = ""
            # branches
            for key, value in brnch.iteritems():
                type, attr, branch_index, block = key.split("_")
                if block == index:
                    branches_str += ", " + branches_obj[int(value)]['Sigla'] + ", " + request.POST[
                        "branch_range_" + branch_index + "_" + index]
            b_str = "\'" + (select + nodes + k_n + e_n + f_n + q_n + branches_str) + "\'"
            blocks_str += b_str + "\n"

        proj_str = sysvar_str + node_str + blocks_str
        print proj_str

        new_project = Project(
            name=request.POST['project-name'],
            user=request.user,
            matlab_file=ContentFile(proj_str, request.POST['project-name'] + ".txt"),
            proj_desc=request.POST['project-desc'],
        )

        try:
            new_project.save()
            messages.add_message(request, messages.SUCCESS, 'Project successfully created')
            return redirect('index')
        except IntegrityError as e:
            messages.add_message(request, messages.ERROR, 'Error Editing Project, Retry')
            return redirect('editor')

    return redirect('editor')


def launch_project(request, project_id):
    if project_id:
        project = Project.objects.get(id=project_id)
        messages.add_message(request, messages.SUCCESS, 'Project ' + project.name + ' launched')
        from watchdog.observers import Observer
        import time, os

        filepath = os.path.dirname(project.matlab_file.name)

        # observer = Observer()
        observer = Observer()
        observer.setName("obsv-"+project_id)
        event_handler = MyHandler(observer, project)
        path = settings.MEDIA_ROOT + "/" + filepath
        print("path observed: " + path)

        observer.schedule(event_handler, path=path, recursive=True)
        observer.start()

        time.sleep(15)
        observer.stop()
        observer.join()
        if observer.is_alive:
            print(observer.name + ": i'm still alive")

        return redirect('index')

    return redirect('index')
