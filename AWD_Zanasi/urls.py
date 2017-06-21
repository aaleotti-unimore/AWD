from django.conf import settings
from django.conf.urls import url, include
from django.conf.urls.static import static
from django.views.static import serve

from . import views

urlpatterns = [
                  url('^', include('django.contrib.auth.urls')),
                  url(r'^$', views.index, name='index'),
                  url(r'^accounts/', include('registration.backends.hmac.urls')),
                  url(r'^projects/create_project/$', views.create_project, name='create_project'),
                  url(r'^projects/(?P<project_id>[0-9]+)/results/$', views.project_results, name='project_results'),
                  url(r'^projects/(?P<project_id>[0-9]+)/edit/$', views.edit_project, name='edit_project'),
                  url(r'^projects/(?P<project_id>[0-9]+)/delete/$', views.delete_project, name='delete_project'),
                  url(r'^admin/updatecommands$', views.update_commands, name='update_commands'),
                  url(r'^help/$', views.help_page, name='help_page'),
                  url(r'^projects/create_project/editor/$', views.project_editor, name='editor'),
                  url(r'^projects/create_project/editor_response/$', views.project_editor_response,
                      name='editor_response'),
                  url(r'^projects/(?P<project_id>[0-9]+)/launch/$', views.launch_project, name='launch_project')
              ]
