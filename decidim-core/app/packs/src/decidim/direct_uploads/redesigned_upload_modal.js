import { Uploader } from "src/decidim/direct_uploads/redesigned_uploader";
import icon from "src/decidim/redesigned_icon";
import { truncateFilename } from "src/decidim/direct_uploads/upload_utility";

// This class handles logic inside upload modal, but since modal is not inside the form
// logic here moves "upload items" / hidden inputs to form.
export default class UploadModal {
  constructor(button, options = {}) {
    // Button that opens the modal.
    this.button = button;

    // The provided options contains the options passed from the view in the
    // `data-upload` attribute as a JSON.
    let providedOptions = {};
    try {
      // The providedOptions can contain the following keys:
      // - addAttribute - Field name / attribute of resource (e.g. avatar)
      // - resourceName - The resource to which the attribute belongs (e.g. user)
      // - resourceClass - Ruby class of the resource (e.g. Decidim::User)
      // - optional - Defines if file is optional
      // - multiple - Defines if multiple files can be uploaded
      // - titled - Defines if file(s) can have titles
      // - maxFileSize - Defines maximum file size in bytes
      // - formObjectClass - Class of the current form object (e.g. Decidim::AccountForm)
      providedOptions = JSON.parse(button.dataset.upload);
    } catch (_e) {
      // Don't care about the parse errors, just skip the provided options.
    }

    this.options = Object.assign(providedOptions, options)

    this.name = this.button.name;
    this.modal = document.querySelector(`#${button.dataset.dialogOpen}`);
    this.saveButton = this.modal.querySelector("button[data-dropzone-save]");
    this.modalTitle = this.modal.querySelector("[data-dialog-title]");
    this.dropZone = this.modal.querySelector("[data-dropzone]");

    this.emptyItems = this.modal.querySelector("#dropzone-no-items");
    this.uploadItems = this.modal.querySelector("#dropzone-items");
    this.input = this.dropZone.querySelector("input");
    this.items = []

    this.attachmentCounter = 0;
    this.locales = JSON.parse(this.uploadItems.dataset.locales);

    this.updateDropZone();
  }

  uploadFile(file) {
    const uploader = new Uploader(this, {
      file: file,
      url: this.input.dataset.directUploadUrl,
      attachmentName: file.name
    });

    const item = this.createUploadItem(file, uploader.errors)

    // add the item to the DOM, before validations
    this.uploadItems.appendChild(item);

    if (!uploader.errors.length) {
      uploader.upload.create((error, blob) => {
        if (error) {
          uploader.errors = [error]
        } else {
          // append to the file object some custom attributes in order to build the form properly
          let name = `${this.options.resourceName}[${this.options.addAttribute}]`
          if (this.options.titled) {
            const ordinalNumber = this.getOrdinalNumber();

            name = `${this.options.resourceName}[${this.options.addAttribute}][${ordinalNumber}][file]`
            file.hiddenTitle = { name: `${this.options.resourceName}[${this.options.addAttribute}][${ordinalNumber}][title]` }
          }

          file.hiddenField = { value: blob.signed_id, name }

          // since the validation step is async, we must wait for the responses
          uploader.validate(blob.signed_id).then(() => {
            if (uploader.errors.length) {
              this.uploadItems.replaceChild(this.createUploadItem(file, uploader.errors, { value: 100 }), item)
            } else {
              // add only the validated files to the array of File(s)
              this.items.push(file)
              // autoload the image
              const reader = new FileReader();
              reader.readAsDataURL(file);
              reader.onload = ({ target: { result }}) => {
                const img = item.querySelector("img")
                img.src = result
              }

              this.updateDropZone();
            }
          });
        }
      });
    }
  }

  getOrdinalNumber() {
    const nextOrdinalNumber = this.attachmentCounter;
    this.attachmentCounter += 1;
    return nextOrdinalNumber;
  }

  updateDropZone() {
    // NOTE: since the FileList HTML attribute of input[type="file"] cannot be set (read-only),
    // we cannot check this.input.files.length when some item is removed
    const inputHasFiles = this.uploadItems.children.length !== 0

    this.uploadItems.hidden = !inputHasFiles;
    this.saveButton.disabled = !inputHasFiles;
    // this.input.disabled = inputHasFiles;
  }

  createUploadItem(file, errors, opts = {}) {
    const okTemplate = `
      <div><img src="" alt="${file.name}" /></div>
      <span>${truncateFilename(file.name)}</span>
    `

    const errorTemplate = `
      <div>${icon("error-warning-line")}</div>
      <div>
        <span>${truncateFilename(file.name)}</span>
        <span>${this.locales.validation_error}</span>
        <ul>${errors.map((error) => `<li>${error}</li>`)}</ul>
      </div>
    `

    const titleTemplate = `
      <div><img src="" alt="${file.name}" /></div>
      <div>
        <div>
          <label>${this.locales.filename}</label>
          <span>${truncateFilename(file.name)}</span>
        </div>
        <div>
          <label>${this.locales.title}</label>
          <input class="sm" type="text" placeholder="${truncateFilename(file.name)}" />
        </div>
      </div>
    `

    let state = "validated"
    let content = okTemplate
    let template = "ok"

    if (errors.length) {
      state = "error"
      content = errorTemplate
      template = "error"
    }

    if (!errors.length && this.options.titled) {
      content = titleTemplate
      template = "titled"
    }

    const fullTemplate = `
      <li data-filename="${file.name}" data-state="${state}">
        <div data-template="${template}">
          ${content.trim()}
          <button>${this.locales.remove}</button>
        </div>
        <progress max="100" value="${opts.value || 0}"></progress>
      </li>`

    const div = document.createElement("div")
    div.innerHTML = fullTemplate.trim()

    const container = div.firstChild

    // append the listeners to the template
    container.querySelector("button").addEventListener("click", this.handleButtonClick.bind(this))

    return container;
  }

  handleButtonClick({ currentTarget }) {
    const item = currentTarget.closest("[data-filename]")
    const { filename } = item.dataset

    // remove item from DOM
    item.remove();

    // remove item from array of File(s), if exists (it could be non-validated)
    const ix = this.items.findIndex(({ name }) => name === filename)
    if (ix) {
      this.items.splice(ix, 1)
    }

    this.updateDropZone();
  }

  setProgressBar(name, value) {
    this.uploadItems.querySelector(`[data-filename="${name}"] progress`).value = value
  }

  updateAddAttachmentsButton() {
    if (this.uploadItems.children.length === 0) {
      this.button.innerHTML = this.modalTitle.dataset.addlabel;
    } else {
      this.button.innerHTML = this.modalTitle.dataset.editlabel;
    }
  }
}
