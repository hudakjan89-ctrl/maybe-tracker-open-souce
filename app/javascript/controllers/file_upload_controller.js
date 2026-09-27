import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileName", "uploadArea", "uploadText"]
  static values = { autosubmit: { type: Boolean, default: false } }

  connect() {
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("change", this.fileSelected.bind(this))
    }

    this.form = this.element.closest("form")
    if (this.form) {
      this.form.addEventListener("turbo:submit-start", this.formSubmitting.bind(this))
    }
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("change", this.fileSelected.bind(this))
    }

    if (this.form) {
      this.form.removeEventListener("turbo:submit-start", this.formSubmitting.bind(this))
    }
  }

  triggerFileInput() {
    if (this.hasInputTarget) {
      this.inputTarget.click()
    }
  }

  dragOver(event) {
    event.preventDefault()
    if (this.hasUploadAreaTarget) {
      this.uploadAreaTarget.classList.add("bg-container-inset")
    }
  }

  dragLeave(event) {
    event.preventDefault()
    if (this.hasUploadAreaTarget) {
      this.uploadAreaTarget.classList.remove("bg-container-inset")
    }
  }

  drop(event) {
    event.preventDefault()
    if (this.hasUploadAreaTarget) {
      this.uploadAreaTarget.classList.remove("bg-container-inset")
    }

    const files = event.dataTransfer?.files
    if (!files || files.length === 0 || !this.hasInputTarget) return

    const transfer = new DataTransfer()
    transfer.items.add(files[0])
    this.inputTarget.files = transfer.files
    this.fileSelected()
  }

  fileSelected() {
    if (this.hasInputTarget && this.inputTarget.files.length > 0) {
      const fileName = this.inputTarget.files[0].name

      if (this.hasFileNameTarget) {
        const fileNameText = this.fileNameTarget.querySelector("p")
        if (fileNameText) {
          fileNameText.textContent = fileName
        }

        this.fileNameTarget.classList.remove("hidden")
      }

      if (this.hasUploadTextTarget) {
        this.uploadTextTarget.classList.add("hidden")
      }

      if (this.autosubmitValue && this.form) {
        this.form.requestSubmit()
      }
    }
  }

  formSubmitting() {
    if (this.hasFileNameTarget && this.hasInputTarget && this.inputTarget.files.length > 0) {
      const fileNameText = this.fileNameTarget.querySelector("p")
      if (fileNameText) {
        fileNameText.textContent = `Spracúvam ${this.inputTarget.files[0].name}…`
      }

      const iconContainer = this.fileNameTarget.querySelector(".lucide-file-text")
      if (iconContainer) {
        iconContainer.classList.add("animate-pulse")
      }
    }

    if (this.hasUploadAreaTarget) {
      this.uploadAreaTarget.classList.add("opacity-70")
    }
  }
}
