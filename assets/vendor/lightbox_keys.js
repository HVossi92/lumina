const LightboxKeys = {
  mounted() {
    this.boundHandleKeydown = this.handleKeydown.bind(this);
    document.addEventListener("keydown", this.boundHandleKeydown);
  },

  destroyed() {
    document.removeEventListener("keydown", this.boundHandleKeydown);
  },

  handleKeydown(event) {
    const key = event.key;
    if (key === "Escape" || key === "ArrowLeft" || key === "ArrowRight") {
      event.preventDefault();
      this.pushEvent("lightbox_keydown", { key });
    }
  },
};

export default LightboxKeys;
