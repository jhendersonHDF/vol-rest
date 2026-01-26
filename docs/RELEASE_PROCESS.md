These are the steps to follow when creating a new release of the HDF5 REST VOL connector:

0. Ensure all changes are ready for the release and committed to the repository, including the `CHANGELOG.md` file in the `docs/` directory

1. Update the `VERSION` file in the root of the source tree with the new version number

2. Commit the change to the `VERSION` file, using the version number as the commit message

    <b>Example:</b>
    ```bash
    git add VERSION
    git commit -m "v0.2.0"
    git push
    ```

3. Create a tag pointing to the commit from the previous step

    <b>Example with signed tag:</b>
    ```bash
    git tag -s v0.2.0 -m "HDF5 REST VOL 0.2.0"
    ```

    <b>Example with unsigned tag:</b>
    ```bash
    git tag -a v0.2.0 -m "HDF5 REST VOL 0.2.0"
    ```

4. Push the tag from the previous step, triggering the release workflow

    <b>Example:</b>
    ```bash
    git push origin v0.2.0
    ```

5. On GitHub, edit the draft release created by the release workflow to tidy up any details, then publish the release when finished
