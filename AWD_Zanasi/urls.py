from django.conf.urls import url, include

from . import views

urlpatterns = [
    url('^', include('django.contrib.auth.urls')),
    url(r'^$', views.index, name='index'),
    url(r'^login/$', views.login_page, name='login'),
    url(r'^logmeout/$', views.logout_view, name='logmeout'),
    url(r'^register/$', views.register, name='register'),
    url(r'^profile/$', views.profile, name='profile'),
    url(r'^projects/create_project/$', views.create_project, name='create_project'),
]
