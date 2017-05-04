# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import logging
from django.shortcuts import redirect
from django.contrib.auth import authenticate, login, logout
from django.http import HttpResponse, HttpResponseRedirect
from django.template import RequestContext

from django.shortcuts import render

# Create your views here.
logger = logging.getLogger(__name__)

from django import forms


def index(request):
    return render(request, 'AWD_Zanasi/home.html')


def login_page(request):
    if request.method == 'POST':
        username = request.POST['username']
        password = request.POST['password']
        user = authenticate(username=username, password=password)
        logger.debug("USER IS " + username + "PW is " + password)
        if user is not None:
            if user.is_active:
                login(request, user)
                return redirect('index')
            else:
                return redirect('login_page')

        else:
            return redirect('login_page')
    return render(request, 'registration/login.html')

def logout_view(request):
    logout(request)
    return redirect('index')


class NameForm(forms.Form):
    your_name = forms.CharField(label='Your name', max_length=100)
