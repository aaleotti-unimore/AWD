# -*- coding: utf-8 -*-
"""
Views Module
"""
from __future__ import unicode_literals

import csv
import logging.config
import os
import shutil
import subprocess
import sys
import time

from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.contrib.auth.decorators import user_passes_test
from django.db import IntegrityError
from django.http import JsonResponse
from django.shortcuts import render, redirect, HttpResponse

from watchdog_handler import watchdog
from .forms import NewProjectForm, EditProjectForm, LoadCommandsListForm
from .models import *

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def index(request):
    """
    Index page. request if a user is authenticated and prompts him to login. 
    If the user is already signed shows the home page containing all the users' projects 
    """

    if request.user.is_authenticated:
        if request.user.is_superuser:
            projects = Project.objects.all().order_by('name')
            results = ProjectOutput.objects.all()
        else:
            projects = Project.objects.filter(user=request.user).order_by('name')
            results = ProjectOutput.objects.filter(project__in=projects)
        return render(request, 'AWD_Zanasi/home.html',
                      {
                          'projects': projects,
                          'project_outputs': results
                      }
                      )
    return render(request, 'AWD_Zanasi/home.html')


@login_required
def create_project(request):
    """
    View for Create Project page. Accepts a POST request containing the project name, description and project .txt files. 
    The Form is validated by Django Forms before assignment then a new project is created with those informations.
    A success message is showed to the user after a new project is saved and the user redirected to the index page.
    
    """
    if request.method == 'POST':
        form = NewProjectForm(request.POST, request.FILES)
        if form.is_valid():
            # controlla se esiste gia
            existing = Project.objects.filter(name=form.cleaned_data['name'])
            if existing:
                messages.add_message(request, messages.ERROR, "Project name already existing")
                return render(request, 'AWD_Zanasi/projects/create_project.html', {'form': NewProjectForm()})
            # crea nuovo progetto
            new_project = Project(
                name=form.cleaned_data['name'],
                user=request.user,
                matlab_file=form.cleaned_data['matlab_file'],
                proj_desc=form.cleaned_data['proj_desc'],
            )

            new_project.save()
            return redirect('index')
        else:
            messages.add_message(request, messages.ERROR, "Invalid Form")
    else:
        HttpResponse(request, 'ERROR')

    return render(request, 'AWD_Zanasi/projects/create_project.html', {'form': NewProjectForm()})


@login_required
def project_results(request, project_id):
    """
    Renders a :model:'AWD_Zanasi.Project' with his results files. 
    if the files are not utf-8 encoded, the function returns an error message and redirects to index page
    :param request: http request
    :param project_id: project id
    :return: renders :template:'AWD_Zanasi/projects/project_results.html' if there are no errors, otherwise :template:`AWD_Zanasi/home.html'`
    """
    if project_id:
        try:
            project = Project.objects.get(id=project_id)

            output = ProjectOutput.objects.filter(project=project)
            outs = list(output)

            # if __check_encoding(os.path.join(settings.MEDIA_ROOT, project.matlab_file.name)):
            return render(request, 'AWD_Zanasi/projects/project_results.html',
                          {'project': project, 'project_output': output})
            # else:
            #     messages.add_message(request, messages.ERROR, 'Error Opening project file: bad encoding')
        except IOError as e:
            logger.error("Project " + project_id + " does not exists")
            messages.add_message(request, messages.ERROR, 'Project ID not found')

    return redirect('index')


@login_required
def edit_project(request, project_id):
    """
    Edit project page renders :template:`AWD_Zanasi/projects/edit_project.html`. 
    if the page receives a POST request containing the edited code, saves the file to its :model:'AWD_Zanasi.Project' and redirects to index.
    
    if the files are not utf-8 encoded, the function returns an error message and redirects to index page

    
    :param request: http request
    :param project_id: project id
    :return: 
    """
    try:
        project = Project.objects.get(id=project_id)
        matlab_filename = project.matlab_file.path

        logger.debug('PROJECT ' + project.name)
        logger.debug('matlab file %s' % project.matlab_file.path)
        # if not __check_encoding(matlab_filename):
        #     messages.add_message(request, messages.ERROR, "Error opening project: Bad Encoding")
        #     return redirect('index')

        if request.method == 'POST':
            form = EditProjectForm(request.POST)

            if form.is_valid():
                actual_name = project.name
                existing = Project.objects.filter(user=request.user).filter(
                    name=form.cleaned_data['proj_name']).exclude(id=project.id)
                if existing:
                    messages.add_message(request, messages.ERROR, "Project name already existing")
                    return render(request, 'AWD_Zanasi/projects/edit_project.html',
                                  {'project': project, 'form': form})

                delete_all(project.matlab_file.path)

                new_name = form.cleaned_data['proj_name']
                new_project = Project(
                    name=new_name,
                    user=request.user,
                    proj_desc=form.cleaned_data['proj_desc'],
                )

                new_project.matlab_file.save("%s.txt" % form.cleaned_data['proj_name'],
                                             ContentFile(form.cleaned_data['proj_code']))

                new_project.save()
                logger.debug("New project created: %s" % new_project.name)
                logger.debug("Matlab File %s " % new_project.matlab_file.path)
                old_proj_path = os.path.join(settings.MEDIA_ROOT, 'user_%s' % request.user, project.name)
                project.delete()
                try:
                    if actual_name != new_name:
                        shutil.rmtree(old_proj_path)
                        logger.debug("succesfully deleted %s" % old_proj_path)
                except WindowsError as e:
                    logger.error(e)

                messages.add_message(request, messages.SUCCESS, 'Project successfully edited')
                return redirect('index')
            else:
                messages.add_message(request, messages.ERROR, 'Error Editing Project: unable to open project file')
                return redirect('edit_project', project_id)

        form = EditProjectForm(initial={'proj_name': project.name, 'proj_code': project.display_source_file(),
                                        'proj_desc': project.proj_desc})
        return render(request, 'AWD_Zanasi/projects/edit_project.html',
                      {'project': project, 'form': form})

    except IOError as e:
        messages.add_message(request, messages.ERROR, "Project ID not found")

    return redirect('index')


@login_required
def delete_project(request, project_id):
    """
    receives a project delete requst from the index page "delete" button. if the project id exists, deletes it
    :param request: HTTP request
    :param project_id: project ID
    :return: redirects to index
    """
    if request.method == 'POST':
        if project_id:
            project = Project.objects.get(id=project_id)
            if project:
                # folder_to_delete = settings.MEDIA_ROOT + "\\" + project.project_folder
                # logger.debug("folder to delete %s" % folder_to_delete )
                outpath = os.path.join(settings.MEDIA_ROOT, "user_%s" % request.user, project.name)
                logger.debug("Out path to delete %s" % outpath)
                project.delete()
                logger.debug("project %s deleted" % project.name)

                delete_all(outpath)
                messages.add_message(request, messages.SUCCESS, 'Project successfully deleted')
            else:
                messages.add_message(request, messages.ERROR, 'Project not found')
        else:
            messages.add_message(request, messages.ERROR, 'Project id not valid')

    return redirect('index')


# noinspection PyCompatibility
@user_passes_test(lambda u: u.is_superuser)
def update_commands(request):
    """
    Admin page only. 
    Used to update POG commands to the database.
    the function accepts a POST request containing CSV files of POG commands. The files are read, converted into dictionaries and saved to database
    
    :param request: http request
    :return: renders :template:'AWD_Zanasi.updatecommands.html'
    """
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
    """
    Help Page
    Renders all three POG command lists
    :param request: HTTP request
    :return: renders :template:'AWD_Zanasi.help.html'
    """
    blocks = CommandBlock.objects.all()
    system = CommandSystem.objects.all()
    branches = CommandBranch.objects.all()

    return render(request, 'AWD_Zanasi/help.html',
                  {"blocks": blocks,
                   "branches": branches,
                   "system": system})


@login_required
def project_generator(request):
    """
    Renders the project generator page. accessed by "Create Project" menu
    :param request: HTTP Request
    :return: renders :template:'AWD_Zanasi/projects/project_generator.html'
    """
    blocks = CommandBlock.objects.values("Sigla", "E_name", "K_name", "Q_name", "F_name", "Help", "Help_ENG")
    system = CommandSystem.objects.values("Nome", "Range", "Help_ENG", "Help")
    branches = CommandBranch.objects.values("Nome", "Range", "Help_ENG", "Help")
    if request.method == 'POST':
        return JsonResponse({'blocks': list(blocks), 'sysvar': list(system), "branches": list(branches)})

    return render(request, 'AWD_Zanasi/projects/project_generator.html')


@login_required
def project_generator_handler(request):
    """
    Handles the request of a new project from the Projet generator page.
    Reads a dictionary from the request.POST objects and converts it in a POG modeler code string saved into a Project file.
    The request.POST dictionary is read and divided into different dictionaries meaning the different parts of the POG code. 
    First are defined the system variables ( CommandSystem ), prefixed by "**" in the POG Code and wrote into a string one line per System command ( named sysvar in this code)
    Second are defined the nodes which every block is defined (prefixed by the "*P" string )
    Third are defined the Blocks with their nodes, then the K,Q,F,E variable names and finally the CommandBranch strings.
    
    :param request: 
    :return: 
    """
    blocks_obj = list(CommandBlock.objects.values("Sigla"))
    branches_obj = list(CommandBranch.objects.values("Sigla"))
    sysvar_obj = list(CommandSystem.objects.values("Sigla"))
    if request.method == 'POST':
        blk = {}  # blocks dictionary - CommandBlock model
        brnch = {}  # branches dictionary - CommandBranch model
        ssvr = {}  # sysvars dictionary - CommandSystem models
        nds = {}  # nodes dictionary - nodes for the CommandBlock items

        blocks_str = ""
        sysvar_str = ""
        node_str = "*P"

        # Command dictionaries generation. Checks the prefix of every dictionary entry, dividing it into different dictionaries
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

        # Command System objects
        for key, value in ssvr.iteritems():
            type, attr, index = key.split("_")
            s_str = "**, %s, %s" % (
                str(sysvar_obj[int(value)]['Sigla']), str(request.POST['sysvar_range_' + index]))
            sysvar_str += s_str + "\n"

        # Nodes string generation
        for key, value in nds.iteritems():
            type, attr, index = key.split("_")  # example  *P, A=(1+1i*1.5), 1=(2+1i*5), c=(-1+1i*3)
            node_str += ", %s=(%s+1i*%s)" % (value, request.POST["coord_x_" + index], request.POST["coord_y_" + index])

        node_str = "" + node_str + "\n"

        # CommandBlocks generation
        for key, value in blk.iteritems():
            type, attr, index = key.split("_")  # example cmd_select_1

            # block variables names. corresponding to E_name, K_name, Q_name, F_name
            k_n, q_n, e_n, f_n = ["", "", "", ""]

            # Sigla value of a CommandBlock
            select = blocks_obj[int(value)]['Sigla'] + ", "

            # Nodes of a CommandBlock
            nodes = request.POST['cmd_node-1_' + index] + ", " + request.POST['cmd_node-2_' + index]

            # Checking if E_name, K_name, Q_name, F_name are present
            if request.POST['cmd_input-K_' + index]:
                k_n = ", Kn, " + request.POST['cmd_input-K_' + index]

            if request.POST['cmd_input-E_' + index]:
                e_n = ", En, " + request.POST['cmd_input-E_' + index]

            if request.POST['cmd_input-F_' + index]:
                f_n = ", Fn, " + request.POST['cmd_input-F_' + index]

            if request.POST['cmd_input-Q_' + index]:
                q_n = ", Qn, " + request.POST['cmd_input-Q_' + index]
            # ----- End variables definition

            # Branches attached to a CommandBlock
            branches_str = ""
            for key, value in brnch.iteritems():
                type, attr, branch_index, block = key.split("_")
                if block == index:
                    branches_str += ", " + branches_obj[int(value)]['Sigla'] + ", " + request.POST[
                        "branch_range_" + branch_index + "_" + index]
            # ----- End Branches definition

            b_str = (select + nodes + k_n + e_n + f_n + q_n + branches_str)  # single block line
            blocks_str += b_str + "\n"  # multipe blocks string

        proj_str = sysvar_str + node_str + blocks_str  # project code string
        logger.debug(proj_str)

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


@login_required
def launch_project(request, project_id):
    """
    Responds to a projects execution request
    Calls the watchdog function from watchdog_handler.py to handle the matlab execution
    :param request: HTTP Request
    :param project_id: Project Id
    :return: Renders Index with a success message when the elaboration is finished 
    """
    if project_id:
        project = Project.objects.get(id=project_id)
        project_out = ProjectOutput.objects.filter(project=project)
        if project_out:
            for out in project_out:
                out.delete()

            outpath = os.path.join(settings.MEDIA_ROOT, "user_%s" % request.user, project.name, "out")
            logger.debug("Out path to delete %s" % outpath)

            delete_all(outpath)
            time.sleep(1)
        watchdog(project)
        messages.add_message(request, messages.SUCCESS, 'Project ' + project.name + ': elaboration complete')
        return redirect('index')

    return redirect('index')


#
# def __check_encoding(filename):
#     """
#     Private function, check if the txt file is utf-8 encoded. prevents rendering errors
#     :param filename: txt file
#     :return: returns a boolean  for success or fail
#     """
#     try:
#         f = codecs.open(filename, encoding='utf-8', errors='strict')
#         for line in f:
#             pass
#         logger.debug("Valid utf-8")
#         return True
#     except UnicodeDecodeError:
#         logger.error("invalid utf-8")
#         return False


@login_required
def examples(request):
    """
    Renders the example page
    :param request: HTTP Request
    :return: renders the Example Page
    """
    projects = Project.objects.filter(is_example=True)
    return render(request, 'AWD_Zanasi/examples.html', {'projects': projects})


@login_required()
def manual(request):
    from watchdog_handler import MAXTIME
    return render(request, 'AWD_Zanasi/manual.html', {'WATCHDOG_TIMEOUT': MAXTIME})


def delete_all(outpath):

    # os.rmdir(outpath)
    # import thread, multiprocessing
    # # create the process pool once
    # process_pool = multiprocessing.Pool(1)
    # results = []
    try:
        #     files = os.listdir(outpath)
        #     for filename in files:
        #         logger.debug("%s" % filename)
        #         thread.start_new_thread(os.remove, (file,))
        #         # later on removing a file in async fashion
        #         # note: need to hold on to the async result till it has completed
        #         results.append(process_pool.apply_async(os.remove, filename),
        #                        )
        #     os.rmdir(outpath)
        # results = subprocess.check_output(
        #     "C:\Apache24\htdocs\AWD\AWD_Zanasi\delfiles.bat \"%s\" " % outpath,
        #     shell=True)
        # logger.debug("Deletion script output: %s" % results)
        # logger.debug("Directory succesfully deleted")
        shutil.rmtree(outpath)
    except WindowsError as e:
        logger.error(e)
