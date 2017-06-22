import logging.config
from datetime import datetime
from watchdog.events import FileSystemEventHandler
from .models import *

logging.config.fileConfig("AWD_Zanasi/configs/logging.conf")
logger = logging.getLogger(__name__)

from watchdog.observers import Observer
import time, os


def watchdog(project):
    global ALIVE
    ALIVE = True
    filepath = os.path.dirname(project.matlab_file.name)

    # observer = Observer()
    observer = Observer()
    observer.setName("obsv-" + str(project.id))
    event_handler = MyHandler(project)
    path = settings.MEDIA_ROOT + "/" + filepath
    print("path observed: " + path)

    observer.schedule(event_handler, path=path, recursive=True)
    observer.start()
    i = 0
    while ALIVE:
        time.sleep(1)
        print(observer.getName() + ": still alive " + str(i))
        i += 1

    print(observer.getName() + ": is dead")
    observer.stop()
    observer.join()
    return 0


class MyHandler(FileSystemEventHandler):
    def __init__(self, project):
        object.__init__(self)
        self.project = project
        self.project.launch_date = datetime.today()
        self.project.save()

    def process(self, event):
        """
        event.event_type 
            'modified' | 'created' | 'moved' | 'deleted'
        event.is_directory
            True | False
        event.src_path
            path/to/observed/file
        """
        # the file will be processed

        if event.src_path.endswith(".txt"):
            self.out = ProjectOutput(
                project=self.project
            )
            root, text_file_path = event.src_path.split(settings.MEDIA_ROOT+"/")
            print("root " + root)
            print("out file path " + text_file_path)
            self.out.text_file.name = text_file_path
            self.out.save()
            print(event.src_path + " saved to databse to project " + str(self.project))

        if event.src_path.endswith(".png"):
            self.out = ProjectOutput(
                project=self.project
            )
            root, img_file_path = event.src_path.split(settings.MEDIA_ROOT+"/")
            print("root " + root)
            print("out file path " + img_file_path)
            self.out.image_file.name = img_file_path
            self.out.save()
            print(event.src_path + " saved to databse to project " + str(self.project))

        if event.src_path.endswith(".done"):
            print("done file found")
            global ALIVE
            ALIVE = False

        print(str(event.src_path) + " " + str(event.event_type))  # print now only for debug

    def on_modified(self, event):
        self.process(event)

    def on_created(self, event):
        self.process(event)
