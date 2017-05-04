from django.conf.urls import url, include

from . import views

urlpatterns = [
    url('^', include('django.contrib.auth.urls')),
    url(r'^$', views.index, name='index'),
    url(r'^login/$', views.login_page, name='login'),
    url(r'^logmeout/$', views.logout_view, name='logmeout'),
]
