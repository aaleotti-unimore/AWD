# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import logging

from django.shortcuts import render, redirect

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
    form = NewProjectForm(request.POST)
    if request.method == 'POST':
        if form.is_valid():
            return redirect('index')
    return render(request, 'AWD_Zanasi/projects/createproject.html', {'form': form})
