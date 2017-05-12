from django.conf.urls import url, include

from . import views

urlpatterns = [
    url('^', include('django.contrib.auth.urls')),
    url(r'^$', views.index, name='index'),
    url(r'^accounts/', include('registration.backends.hmac.urls')),
    url(r'^projects/create_project/$', views.create_project, name='create_project'),
    url(r'^projects/project_results/$', views.project_results, name='project_results'),

]
