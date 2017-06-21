from watchdog.events import FileSystemEventHandler
from models import ProjectOutput, Project
from datetime import datetime


class MyHandler(FileSystemEventHandler):
    def __init__(self, observer, project):
        object.__init__(self)
        self.project = project
        self.observer = observer
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
            self.out.text_file = event.src_path
            self.out.save()
            print(event.src_path + " saved to databse to project "+ str(self.project))

        if event.src_path.endswith(".png"):
            self.out = ProjectOutput(
                project=self.project
            )
            self.out.image_file = event.src_path
            self.out.save()
            print(event.src_path + " saved to databse to project "+ str(self.project))

        print event.src_path, event.event_type  # print now only for debug

    def on_modified(self, event):
        self.process(event)

    def on_created(self, event):
        self.process(event)
