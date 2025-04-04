var __html5FileExchange = {};
window.__html5FileExchange = __html5FileExchange

__html5FileExchange.upload = function (godotCallback) {
    const input = document.createElement('input');
    input.setAttribute("type", "file");
    input.click();
    input.addEventListener('change', event => {
        if (event.target.files.length > 0) {
            const file = event.target.files[0];
            const reader = new FileReader();
            this.fileType = file.type;
            this.fileName = file.name;
            reader.readAsArrayBuffer(file);
            reader.onloadend = (event) => {
                if (event.target.readyState == FileReader.DONE) {
                    this.result = event.target.result;
                    godotCallback();
                }
            }
        }
    });
}
/*

*/