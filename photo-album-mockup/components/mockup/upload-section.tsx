import { Upload, CloudUpload, FileImage, CheckCircle2, XCircle, Loader2 } from "lucide-react"

export function UploadSection() {
  return (
    <section>
      <h2 className="text-3xl font-serif font-bold text-base-content mb-8 text-balance">Upload Photos</h2>

      {/* Drop zone */}
      <div className="border border-dashed border-base-300 rounded-md p-10 text-center hover:border-accent/50 transition-colors cursor-pointer bg-base-200/40">
        <CloudUpload className="h-8 w-8 text-base-content/20 mx-auto mb-3" strokeWidth={1.5} />
        <p className="text-base-content font-medium text-sm mb-1">
          Drop files here or click to browse
        </p>
        <p className="text-xs text-base-content/40">
          JPG, PNG, WEBP, HEIC up to 50MB each
        </p>
      </div>

      {/* Upload form */}
      <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="form-control">
          <label className="label">
            <span className="label-text text-base-content text-sm">Album</span>
          </label>
          <select className="select select-bordered select-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full">
            <option>Landscapes</option>
            <option>Pets</option>
            <option>City Life</option>
            <option>Create new album...</option>
          </select>
        </div>
        <div className="form-control">
          <label className="label">
            <span className="label-text text-base-content text-sm">Tags</span>
          </label>
          <input
            type="text"
            placeholder="nature, sunset, travel..."
            className="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
          />
        </div>
      </div>

      <div className="form-control mt-4">
        <label className="label">
          <span className="label-text text-base-content text-sm">Description</span>
        </label>
        <textarea
          className="textarea textarea-bordered textarea-sm bg-base-200/60 border-base-300 text-base-content h-20 rounded-md w-full"
          placeholder="Optional description..."
        />
      </div>

      {/* Upload queue */}
      <div className="mt-6">
        <p className="text-[10px] uppercase tracking-[0.15em] text-base-content/40 font-semibold mb-3">
          Upload Queue
        </p>
        <div className="flex flex-col gap-2">
          <div className="flex items-center gap-3 bg-base-200 rounded-md px-4 py-3 border border-base-300">
            <FileImage className="h-4 w-4 text-base-content/30 shrink-0" strokeWidth={1.5} />
            <div className="flex-1 min-w-0">
              <p className="text-sm text-base-content truncate">sunset-beach.jpg</p>
              <p className="text-[11px] text-base-content/40 font-mono">2.4 MB</p>
            </div>
            <CheckCircle2 className="h-4 w-4 text-success shrink-0" strokeWidth={1.5} />
          </div>
          <div className="flex items-center gap-3 bg-base-200 rounded-md px-4 py-3 border border-base-300">
            <FileImage className="h-4 w-4 text-base-content/30 shrink-0" strokeWidth={1.5} />
            <div className="flex-1 min-w-0">
              <p className="text-sm text-base-content truncate">mountain-view.png</p>
              <div className="flex items-center gap-2 mt-1">
                <progress className="progress progress-accent h-1 w-full" value="65" max="100" />
                <span className="text-[11px] text-base-content/40 font-mono shrink-0">65%</span>
              </div>
            </div>
            <Loader2 className="h-4 w-4 text-accent animate-spin shrink-0" strokeWidth={1.5} />
          </div>
          <div className="flex items-center gap-3 bg-base-200 rounded-md px-4 py-3 border border-base-300">
            <FileImage className="h-4 w-4 text-base-content/30 shrink-0" strokeWidth={1.5} />
            <div className="flex-1 min-w-0">
              <p className="text-sm text-base-content truncate">corrupted-file.bmp</p>
              <p className="text-[11px] text-error">Unsupported format</p>
            </div>
            <XCircle className="h-4 w-4 text-error shrink-0" strokeWidth={1.5} />
          </div>
        </div>
      </div>

      <div className="mt-6 flex gap-3">
        <button className="btn btn-sm btn-accent gap-1.5 rounded-md">
          <Upload className="h-4 w-4" strokeWidth={1.5} />
          Upload All
        </button>
        <button className="btn btn-sm btn-ghost">Cancel</button>
      </div>
    </section>
  )
}
