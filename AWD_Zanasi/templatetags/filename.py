import os

from django import template

register = template.Library()


@register.filter
def filename(value):
    """
    returns the name of the file 
    :param value: file path
    :return: filename
    """
    return os.path.basename(value.file.name)
