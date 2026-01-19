# Extend the Library Shop application with a new feature

## Lab 1 - Implement a new feature using LLM

1. Connect to the Fedora 43 system.

2. You should already have the `Visual Studio Code` application opened, if not, go ahead an open it.

3. Make sure you have the `library-shop` project opened, if not, go head and open it by going to the VSCode Menu and click on `File` -> `Open Folder` -> `Carpeta personal` -> `library-shop` -> `Abrir`.

4. Make sure you have a terminal opened, if not, go ahead and open it by going to the top menu, click `Terminal` -> `New Terminal`. You will see a new terminal has been opened at the bottom.


5. Open the chat with the LLM and enter the following prompt:

    ~~~text
    Generate a new resource AuthorResource with an JAXRS endpoint  (method GET) that list the distinct authors (java method name: listAuthors). Generate the appropriate tests (AuthorResourceTest). Review the code, make sure it works and the tests pass.
    ~~~

6. Review and accept if proceed the commands to create the new functionallity.