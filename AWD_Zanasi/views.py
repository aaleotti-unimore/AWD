# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import logging

from django.shortcuts import render, redirect, HttpResponse

from .models import Project, ProjectOutput
from .forms import NewProjectForm

# Create your views here.
logger = logging.getLogger(__name__)


def index(request):
    if request.user.is_authenticated:
        if request.user.is_superuser:
            projects = Project.objects.all()
            results = ProjectOutput.objects.all()
        else:
            projects = Project.objects.filter(user=request.user)
            results = ProjectOutput.objects.all()
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
                res_type=form.cleaned_data['res_type']
            )
            new_project.save()
            return redirect('index')
    else:
        HttpResponse(request, 'ERROR')

    return render(request, 'AWD_Zanasi/projects/createproject.html', {'form': NewProjectForm()})

def project_results(request):
    pass